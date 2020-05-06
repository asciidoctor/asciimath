require_relative 'ast'

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
      '+' => ?+,
      '-' => ?-,
      '*' => ?*,
      'slash' => ?/,
      'eq' => ?=,
      'ne' => "\\neq",
      'assign' => ":=",
      'lt' => ?<,
      'gt' => ?>,
      'sub' => "\\text{–}",
      'sup' => "\\text{^}",
      'implies' => "\\Rightarrow",
      'iff' => "\\Leftrightarrow",
      'if' => "\\text{if}",
      'and' => "\\text{and}",
      'or' => "\\text{or}",
      'lparen' => ?(,
      'rparen' => ?),
      'lbracket' => ?[,
      'rbracket' => ?],
      'lbrace' => "\\{",
      'rbrace' => "\\}",
      'lvert' => "\\lVert",
      'rvert' => "\\rVert",
      'vbar' => ?|,
      nil => ?.,
      'integral' => "\\int",
      'dx' => "dx",
      'dy' => "dy",
      'dz' => "dz",
      'dt' => "dt",
      'contourintegral' => "\\oint",
      'Lim' => "\\text{Lim}",
      'Sin' => "\\text{Sin}",
      'Cos' => "\\text{Cos}",
      'Tan' => "\\text{Tan}",
      'Sinh' => "\\text{Sinh}",
      'Cosh' => "\\text{Cosh}",
      'Tanh' => "\\text{Tanh}",
      'Cot' => "\\text{Cot}",
      'Sec' => "\\text{Sec}",
      'csc' => "\\text{csc}",
      'Csc' => "\\text{Csc}",
      'sech' => "\\text{sech}",
      'csch' => "\\text{csch}",
      'Abs' => "\\text{Abs}",
      'Log' => "\\text{Log}",
      'Ln' => "\\text{Ln}",
      'lcm' => "\\text{lcm}",
      'lub' => "\\text{lub}",
      'glb' => "\\text{glb}",
      'partial' => "\\del",
      'prime' => ?',
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
        when AsciiMath::AST::Sequence
          len = expression.length - 1

          expression.each_with_index do |e, i|
            append(e)
            @latex << separator if i != len
          end

        when AsciiMath::AST::Symbol
          @latex << symbol(expression.text)

        when AsciiMath::AST::Identifier
          append_escaped(expression.value)

        when AsciiMath::AST::Text
          text do
            append_escaped(expression.value)
          end

        when AsciiMath::AST::Number
          @latex << expression.value

        when AsciiMath::AST::Paren
          parens(expression.lparen, expression.rparen) do
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
          op = expression.operator.text

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
              append(AsciiMath::AST::symbol('frown'))
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
          op = expression.operator.text

          case op
          when :root
            macro("sqrt", expression.operand1) do
              append(expression.operand2)
            end
        
          when :color
            curly do
              color do
                @latex << expression.operand1.text
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
          
          parens(expression.lparen, expression.rparen) do
            @latex << "\\begin{matrix} "

            expression.each_with_index do |row, i|
              append(row, " & ")
              @latex << " \\\\ " if i != len
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
