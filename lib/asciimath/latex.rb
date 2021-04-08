require_relative 'ast'

module AsciiMath
  class LatexBuilder
    attr_reader :symbol_table

    def initialize(symbol_table = nil)
      @latex = ''
      @symbol_table = symbol_table.nil? ? DEFAULT_DISPLAY_SYMBOL_TABLE : symbol_table
    end

    def to_s
      @latex
    end

    def append_expression(expression)
      append(expression)
      self
    end
    
    DEFAULT_DISPLAY_SYMBOL_TABLE = {
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
      :percent => "\\%",
      :exclamation => ?!,
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
      :nbsp => "\\;",
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
      :roman => "\\mathrm",
    }.freeze

    private

    SPECIAL_CHARACTERS = [?&, ?%, ?$, ?#, ?_, ?{, ?}, ?~, ?^, ?[, ?]].map(&:ord)

    COLOURS = {
      [0xFF, 0xFF, 0xFF] => "white",
      [0xFF, 0x00, 0x00] => "red",
      [0x00, 0xFF, 0x00] => "green",
      [0x00, 0x00, 0xFF] => "blue",
      [0xBF, 0x80, 0x40] => "brown",
      [0x00, 0xAD, 0xEF] => "cyan",
      [0x40, 0x40, 0x40] => "darkgray",
      [0x80, 0x80, 0x80] => "gray",
      [0xBF, 0xBF, 0xBF] => "lightgray",
      [0xA4, 0xDB, 0x00] => "lime",
      [0xE9, 0x00, 0x8A] => "magenta",
      [0x8E, 0x86, 0x00] => "olive",
      [0xFF, 0x80, 0x00] => "orange",
      [0xFF, 0xBF, 0xBF] => "pink",
      [0xBF, 0x00, 0x40] => "purple",
      [0x00, 0x80, 0x80] => "teal",
      [0x80, 0x00, 0x80] => "violet",
      [0xFF, 0xF2, 0x00] => "yellow",
    }

    def append(expression, separator = " ")
      case expression
        when Array
          expression.each { |e| append(e, separator) }
        when String
          @latex << expression
        when Symbol
          @latex << expression.to_s
        when AsciiMath::AST::Sequence, AsciiMath::AST::MatrixRow 
          c = expression.length

          expression.each do |e|
            c -= 1
            append(e)
            @latex << separator if c > 0
          end

        when AsciiMath::AST::Symbol
          @latex << resolve_symbol(expression.value)

        when AsciiMath::AST::Identifier
          append_escaped(expression.value)

        when AsciiMath::AST::Text
          text do
            append_escaped(expression.value)
          end

        when AsciiMath::AST::Number
          @latex << expression.value

        when AsciiMath::AST::Paren
          parens(expression.lparen, expression.rparen, expression.expression)

        when AsciiMath::AST::Group
          append(expression.expression)

        when AsciiMath::AST::SubSup
          sub = expression.sub_expression
          sup = expression.sup_expression
          e = expression.base_expression

          curly(e)

          if sub
            @latex << "_"
            curly(sub)
          end       

          if sup
            @latex << "^"
            curly(sup)
          end

        when AsciiMath::AST::UnaryOp
          op = expression.operator.value

          case op
          when :norm
            parens(:lvert, :rvert, expression.operand)
          when :floor
            parens(:lfloor, :rfloor, expression.operand)
          when :ceil
            parens(:lceiling, :rceiling, expression.operand)
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
              color_value = expression.operand1
              red = color_value.red
              green = color_value.green
              blue = color_value.blue

              if COLOURS.has_key? [red, green, blue]
                  color do
                    @latex << COLOURS[[red, green, blue]]
                  end
              else
                color('RGB') do
                  @latex << red.to_s << ',' << green.to_s << ',' << blue.to_s
                end
              end

              @latex << " "
              append(expression.operand2)
            end

          else
            @latex << resolve_symbol(op)

            curly do
              append(expression.operand1)
            end

            curly do
              append(expression.operand2)
            end
          end
        
        when AsciiMath::AST::Matrix
          parens(expression.lparen, expression.rparen) do
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
      @latex << resolve_symbol(macro)

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

    def parens(lparen, rparen, content = nil, &block)
      l = lparen.is_a?(AsciiMath::AST::Symbol) ? lparen.value : lparen
      r = rparen.is_a?(AsciiMath::AST::Symbol) ? rparen.value : rparen

      if block_given?
        if l || r
          @latex << "\\left " << resolve_symbol(l) << " "
          yield self
          @latex << " \\right " << resolve_symbol(r)
        else
          yield self
        end
      else
        needs_left_right = !is_small(content)

        @latex << "\\left " if needs_left_right
        @latex << resolve_symbol(l) << " " if l or needs_left_right

        append(content)

        @latex << " \\right" if needs_left_right
        @latex << " " << resolve_symbol(r) if r or needs_left_right
      end
    end

    def curly(expression = nil, &block)
      if block_given?
        @latex << ?{
        yield self
        @latex << ?}
      else
        case expression
        when AsciiMath::AST::Symbol, AsciiMath::AST::Text
          append(expression)
          return
        when AsciiMath::AST::Identifier, AsciiMath::AST::Number
          if expression.value.length <= 1
            append(expression)
            return
          end
        end

        @latex << ?{
        append(expression)
        @latex << ?}
      end
    end

    def append_escaped(text)
      text.each_codepoint do |cp|
        @latex << "\\" if SPECIAL_CHARACTERS.include? cp
        @latex << cp
      end
    end

    def resolve_symbol(s)
      symbol = @symbol_table[s]

      case symbol
      when String
        return symbol
      when Hash
        return symbol[:value]
      when nil
        return "\\#{s.to_s}"
      else
        raise "Invalid entry in symbol table"
      end
    end

    def is_small(e)
      case e
        when AsciiMath::AST::SubSup
          is_very_small(e.sub_expression) and is_very_small(e.sup_expression) and is_very_small(e.base_expression)
        when AsciiMath::AST::Sequence
          e.all? { |s| is_small(s) }
        else
          is_very_small(e)
      end
    end

    def is_very_small(e)
      case e
      when AsciiMath::AST::Identifier, AsciiMath::AST::Number
        e.value.length <= 1
      when AsciiMath::AST::Symbol
        case e.value
        when :plus, :minus, :cdot, :dx, :dy, :dz, :dt, :f, :g, :mod
          true
        else
          false
        end
      when AsciiMath::AST::UnaryOp
        case e.operator
        when :hat, :overline, :underline, :vec, :dot, :ddot, :color
          is_very_small(e.operand)
        else
          false
        end
      when AsciiMath::AST::Group
        is_very_small(e.expression)
      when AsciiMath::AST::Sequence
        e.all? { |s| is_very_small(e) }
      when nil
        true
      else
        false
      end
    end
  end

  class Expression
    def to_latex(symbol_table = nil)
      LatexBuilder.new(symbol_table).append_expression(ast).to_s
    end
  end
end
