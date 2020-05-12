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
    }

    COLOURS = {
      [0xFB, 0xB9, 0x82] => "apricot",
      [0x00, 0xB5, 0xBE] => "aquamarine",
      [0xC0, 0x4F, 0x17] => "bittersweet",
      [0x22, 0x1E, 0x1F] => "black",
      [0x2D, 0x2F, 0x92] => "blue",
      [0x00, 0xB3, 0xB8] => "bluegreen",
      [0x47, 0x39, 0x92] => "blueviolet",
      [0xB6, 0x32, 0x1C] => "brickred",
      [0x79, 0x25, 0x00] => "brown",
      [0xF7, 0x92, 0x1D] => "burntorange",
      [0x74, 0x72, 0x9A] => "cadetblue",
      [0xF2, 0x82, 0xB4] => "carnationpink",
      [0x00, 0xA2, 0xE3] => "cerulean",
      [0x41, 0xB0, 0xE4] => "cornflowerblue",
      [0x00, 0xAE, 0xEF] => "cyan",
      [0xFD, 0xBC, 0x42] => "dandelion",
      [0xA4, 0x53, 0x8A] => "darkorchid",
      [0x00, 0xA9, 0x9D] => "emerald",
      [0x00, 0x9B, 0x55] => "forestgreen",
      [0x8C, 0x36, 0x8C] => "fuchsia",
      [0xFF, 0xDF, 0x42] => "goldenrod",
      [0x94, 0x96, 0x98] => "gray",
      [0x00, 0xA6, 0x4F] => "green",
      [0xDF, 0xE6, 0x74] => "greenyellow",
      [0x00, 0xA9, 0x9A] => "junglegreen",
      [0xF4, 0x9E, 0xC4] => "lavender",
      [0x8D, 0xC7, 0x3E] => "limegreen",
      [0xEC, 0x00, 0x8C] => "magenta",
      [0xA9, 0x34, 0x1F] => "mahogany",
      [0xAF, 0x32, 0x35] => "maroon",
      [0xF8, 0x9E, 0x7B] => "melon",
      [0x00, 0x67, 0x95] => "midnightblue",
      [0xA9, 0x3C, 0x93] => "mulberry",
      [0x00, 0x6E, 0xB8] => "navyblue",
      [0x3C, 0x80, 0x31] => "olivegreen",
      [0xF5, 0x81, 0x37] => "orange",
      [0xED, 0x13, 0x5A] => "orangered",
      [0xAF, 0x72, 0xB0] => "orchid",
      [0xF7, 0x96, 0x5A] => "peach",
      [0x79, 0x77, 0xB8] => "periwinkle",
      [0x00, 0x8B, 0x72] => "pinegreen",
      [0x92, 0x26, 0x8F] => "plum",
      [0x00, 0xB0, 0xF0] => "processblue",
      [0x99, 0x47, 0x9B] => "purple",
      [0x97, 0x40, 0x06] => "rawsienna",
      [0xED, 0x1B, 0x23] => "red",
      [0xF2, 0x60, 0x35] => "redorange",
      [0xA1, 0x24, 0x6B] => "redviolet",
      [0xEF, 0x55, 0x9F] => "rhodamine",
      [0x00, 0x71, 0xBC] => "royalblue",
      [0x61, 0x3F, 0x99] => "royalpurple",
      [0xED, 0x01, 0x7D] => "rubinered",
      [0xF6, 0x92, 0x89] => "salmon",
      [0x3F, 0xBC, 0x9D] => "seagreen",
      [0x67, 0x18, 0x00] => "sepia",
      [0x46, 0xC5, 0xDD] => "skyblue",
      [0xC6, 0xDC, 0x67] => "springgreen",
      [0xDA, 0x9D, 0x76] => "tan",
      [0x00, 0xAE, 0xB3] => "tealblue",
      [0xD8, 0x83, 0xB7] => "thistle",
      [0x00, 0xB4, 0xCE] => "turquoise",
      [0x58, 0x42, 0x9B] => "violet",
      [0xEF, 0x58, 0xA0] => "violetred",
      [0xEE, 0x29, 0x67] => "wildstrawberry",
      [0xFF, 0xF2, 0x00] => "yellow",
      [0x98, 0xCC, 0x70] => "yellowgreen",
      [0xFA, 0xA2, 0x1A] => "yelloworange"

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

    def parens(lparen, rparen, content = nil, &block)
      l = lparen.is_a?(AsciiMath::AST::Symbol) ? lparen.value : lparen
      r = rparen.is_a?(AsciiMath::AST::Symbol) ? rparen.value : rparen

      if block_given?
        if l || r
          @latex << "\\left " << symbol(l) << " "
          yield self
          @latex << " \\right " << symbol(r)
        else
          yield self
        end
      else
        needs_left_right = !is_small(content)

        @latex << "\\left " if needs_left_right
        @latex << symbol(l) << " " if l or needs_left_right

        append(content)

        @latex << " \\right" if needs_left_right
        @latex << " " << symbol(r) if r or needs_left_right
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

    def symbol(s)
      SYMBOLS[s] || "\\#{s.to_s}"
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
    def to_latex
      LatexBuilder.new().append_expression(ast).to_s
    end
  end
end
