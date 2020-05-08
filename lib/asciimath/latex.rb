require_relative 'ast'
require_relative 'markup'

module AsciiMath
  class LatexBuilder
    def initialize
      @latex = ''
    end

    def to_s
      @latex
    end

    def append_expression(expression)
      append(expression)
      self
    end

    private

    SPECIAL_CHARACTERS = [?&, ?%, ?$, ?#, ?_, ?{, ?}, ?~, ?^, ?[, ?]].map(&:ord)

    SYMBOLS = {
      :plus => ?+,
      :minus => ?-,
      :ast => ?*,
      :slash => ?/,
      :eq => ?=,
      :ne => "\\neq",
      :assign => ":=",
      :lt => ?<,
      :gt => ?>,
      :sub => "\\text{–}",
      :sup => "\\text{^}",
      :implies => "\\Rightarrow",
      :iff => "\\Leftrightarrow",
      :if => "\\operatorname{if}",
      :and => "\\operatorname{and}",
      :or => "\\operatorname{or}",
      :lparen => ?(,
      :rparen => ?),
      :lbracket => ?[,
      :rbracket => ?],
      :lbrace => "\\{",
      :rbrace => "\\}",
      :lvert => "\\lVert",
      :rvert => "\\rVert",
      :vbar => ?|,
      nil => ?.,
      :integral => "\\int",
      :dx => "dx",
      :dy => "dy",
      :dz => "dz",
      :dt => "dt",
      :contourintegral => "\\oint",
      :Lim => "\\operatorname{Lim}",
      :Sin => "\\operatorname{Sin}",
      :Cos => "\\operatorname{Cos}",
      :Tan => "\\operatorname{Tan}",
      :Sinh => "\\operatorname{Sinh}",
      :Cosh => "\\operatorname{Cosh}",
      :Tanh => "\\operatorname{Tanh}",
      :Cot => "\\operatorname{Cot}",
      :Sec => "\\operatorname{Sec}",
      :csc => "\\operatorname{csc}",
      :Csc => "\\operatorname{Csc}",
      :sech => "\\operatorname{sech}",
      :csch => "\\operatorname{csch}",
      :Abs => "\\operatorname{Abs}",
      :Log => "\\operatorname{Log}",
      :Ln => "\\operatorname{Ln}",
      :lcm => "\\operatorname{lcm}",
      :lub => "\\operatorname{lub}",
      :glb => "\\operatorname{glb}",
      :partial => "\\del",
      :prime => ?',
      :tilde => "\\~",
      :nbsp => "\\:",
      :lceiling => "\\lceil",
      :rceiling => "\\rceil",
      :dstruck_captial_c => "\\mathbb{C}",
      :dstruck_captial_n => "\\mathbb{N}",
      :dstruck_captial_q => "\\mathbb{Q}",
      :dstruck_captial_r => "\\mathbb{R}",
      :dstruck_captial_z => "\\mathbb{Z}",
      :f => "f",
      :g => "g",
      :to => "\\rightarrow",
      :bold => "\\mathbf",
      :double_struck => "\\mathbb",
      :italic => "\\mathit",
      :bold_italic => "\\mathbf",
      :script => "\\mathscr",
      :bold_script => "\\mathscr",
      :monospace => "\\mathtt",
      :fraktur => "\\mathfrak",
      :bold_fraktur => "\\mathfrak",
      :sans_serif => "\\mathsf",
      :bold_sans_serif => "\\mathsf",
      :sans_serif_italic => "\\mathsf",
      :sans_serif_bold_italic => "\\mathsf",
    }

    def append(expression, separator = " ")
      case expression
        when AsciiMath::AST::Sequence, AsciiMath::AST::MatrixRow 
          c = expression.length

          expression.each do |e|
            c -= 1
            append(e)
            @latex << separator if c > 0
          end

        when AsciiMath::AST::Symbol
          @latex << symbol(expression.value)

        when AsciiMath::AST::Identifier
          append_escaped(expression.value)

        when AsciiMath::AST::Text
          text do
            append_escaped(expression.value)
          end

        when AsciiMath::AST::Number
          @latex << expression.value

        when AsciiMath::AST::Paren
          parens(expression.lparen.value, expression.rparen.value) do
            append(expression.expression)
          end

        when AsciiMath::AST::Group
          append(expression.expression)

        when AsciiMath::AST::SubSup
          sub = expression.sub_expression
          sup = expression.sup_expression
          e = expression.base_expression

          curly(e) do
            append(e)
          end

          if sub
            @latex << "_"
            curly(sub) do
              append(sub)
            end
          end       

          if sup
            @latex << "^"
            curly(sup) do
              append(sup)
            end
          end

        when AsciiMath::AST::UnaryOp
          op = expression.operator.value

          case op
          when :norm
            parens(:lvert, :rvert) do
              append(expression.operand)
            end
          when :floor
            parens(:lfloor, :rfloor) do
              append(expression.operand)
            end
          when :ceil
            parens(:lceiling, :rceiling) do
              append(expression.operand)
            end
          when :overarc
            overset do
              @latex << "\\frown"
            end
            
            curly do
              append(expression.operand)
            end
          else
            macro(op) do
              append(expression.operand)
            end
          end

        when AsciiMath::AST::BinaryOp, AsciiMath::AST::InfixOp
          op = expression.operator.value

          case op
          when :root
            macro("sqrt", expression.operand1) do
              append(expression.operand2)
            end
        
          when :color
            curly do
              color do
                ::AsciiMath::MarkupBuilder.append_color_text(@latex, expression.operand1)
              end

              @latex << " "
              append(expression.operand2)
            end

          else
            @latex << symbol(op)

            curly do
              append(expression.operand1)
            end

            curly do
              append(expression.operand2)
            end
          end
        
        when AsciiMath::AST::Matrix
          len = expression.length - 1
          
          parens(expression.lparen.value, expression.rparen.value) do
            c = expression.length
            @latex << "\\begin{matrix} "

            expression.each do |row|
              c -= 1
              append(row, " & ")
              @latex << " \\\\ " if c > 0
            end

            @latex << " \\end{matrix}"
          end
      end
    end

    def macro(macro, *args)
      @latex << symbol(macro)

      if args.length != 0
        @latex << "["
        append(args, "][")
        @latex << "]"
      end

      if block_given?
        curly do
          yield self
        end
      end
    end

    def method_missing(meth, *args, &block)
      macro(meth, *args, &block)
    end

    def parens(lparen, rparen, &block)
      if lparen || rparen
        @latex << "\\left " << symbol(lparen) << " "
        yield self
        @latex << " \\right " << symbol(rparen)
      else
        yield self
      end
    end

    def curly(expression = nil, &block)
      case expression
      when AsciiMath::AST::Symbol, AsciiMath::AST::Text
        yield self
      when AsciiMath::AST::Identifier, AsciiMath::AST::Number
        if expression.value.length <= 1
          yield self
        else
          @latex << ?{
          yield self
          @latex << ?}
        end
      else
        @latex << ?{
        yield self
        @latex << ?}
      end
    end

    def append_escaped(text)
      text.each_codepoint do |cp|
        @latex << "\\" if SPECIAL_CHARACTERS.include? cp
        @latex << cp
      end
    end

    def symbol(s)
      SYMBOLS[s] || "\\#{s.to_s}"
    end
  end

  class Expression
    def to_latex
      LatexBuilder.new().append_expression(ast).to_s
    end
  end
end
