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

    SPECIAL_CHARACTERS = [?&, ?%, ?$, ?#, ?_, ?{, ?}, ?~, ?^, ?[, ?]]

    SYMBOLS = {
      :plus => ?+,
      :minus => ?-,
      :ast => ?*,
      :slash => ?/,
      :eq => ?=,
      :ne => "\\neq",
      :assign => "TODO",
      :lt => ?<,
      :gt => ?>,
      :implies => "\\Rightarrow",
      :iff => "\\Leftrightarrow",
      :if => "\\text{if}",
      :and => "\\text{and}",
      :or => "\\text{or}",
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
      :partial => "\\del",
      :prime => ?',
      :tilde => "TODO",
      :nbsp => "\\;",
      :quad => "\\;\\;",
      :qquad => "\\;\\;\\;\\;",
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
      :script => "\\mathscr",
      :italic => "\\mathit",
      :monospace => "\\mathtt",
      :fraktur => "\\mathfrak",
      :sans_serif => "\\mathsf"
    }

    def append(expression, separator = " ")
      case expression
        when Array
          len = expression.length - 1
          expression.each_with_index do |e, i|
            append(e)
            @latex << separator if i != len
          end
        when String
          append_escaped(expression)
        when Symbol
            @latex << (SYMBOLS[expression] || "\\#{expression.to_s}")
        when Hash
          case expression[:type]
            when :text
              text do
                append_escaped(expression[:c])
              end

            when :paren
              parens(expression[:lparen], expression[:rparen]) do
                append(expression[:e], separator)
              end

            when :subsup
              sub = expression[:sub]
              sup = expression[:sup]
              e = expression[:e]

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

            when :unary
              op = expression[:op]

              case op
              when :norm
                parens(:lvert, :rvert) do
                  append(expression[:e])
                end
              when Symbol
                macro(op) do
                  append(expression[:e])
                end
              when String
                macro(op) do
                  append(expression[:e])
                end
              else
                raise nil
              end

            when :binary
              op = expression[:op]

              case op
              when :root
                macro("sqrt", expression[:e1]) do
                  append(expression[:e2])
                end
              when Symbol
                @latex << symbol(op)

                curly do
                  append(expression[:e1])
                end

                curly do
                  append(expression[:e2])
                end
              when String
                @latex << op

                curly do
                  append(expression[:e1])
                end

                curly do
                  append(expression[:e2])
                end
              else
                raise nil
              end
            when :matrix
              rows = expression[:rows]
              len = rows.length - 1
              
              parens(expression[:lparen], expression[:rparen]) do
                @latex << "\\begin{matrix} "

                rows.each_with_index do |row, i|
                  append(row, " & ")
                  @latex << " \\\\ " if i != len
                end

                @latex << " \\end{matrix}"
              end
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

    def curly(x = true, &block)
      case x
      when Array, Hash, true
        @latex << "{"
        yield self
        @latex << "}"
      else
        yield self
      end
    end

    def append_escaped(text)
      text.each_codepoint do |cp|
        begin
          @latex << "\\" if SPECIAL_CHARACTERS.include? cp.chr
        rescue
          # Not a unicode character
        ensure
          @latex << cp
        end
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
