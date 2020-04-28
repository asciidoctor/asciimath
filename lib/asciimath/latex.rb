module AsciiMath
  class LatexBuilder
    SPECIAL_CHARACTERS = [?&, ?%, ?$, ?#, ?_, ?{, ?}, ?~, ?^, ?[, ?]]

    CONSTANTS = {
        ?α => "\\alpha",
        ?β => "\\beta",
        ?γ => "\\gamma",
        ?Γ => "\\Gamma",
        ?δ => "\\delta",
        ?Δ => "\\Delta",
        ?ε => "\\epsilon",
        ?ɛ => "\\varepsilon",
        ?ζ => "\\zeta",
        ?η => "\\eta",
        ?θ => "\\theta",
        ?Θ => "\\Theta",
        ?ϑ => "\\vartheta",
        ?ι => "\\iota",
        ?κ => "\\kappa",
        ?λ => "\\lambda",
        ?Λ => "\\Lambda",
        ?μ => "\\mu",
        ?ν => "\\nu",
        ?ξ => "\\xi",
        ?Ξ => "\\Xi",
        ?π => "\\pi",
        ?Π => "\\Pi",
        ?ρ => "\\rho",
        ?σ => "\\sigma",
        ?Σ => "\\Sigma",
        ?τ => "\\tau",
        ?υ => "\\upsilon",
        ?ϕ => "\\phi",
        ?Φ => "\\Phi",
        ?φ => "\\varphi",
        ?χ => "\\chi",
        ?ψ => "\\psi",
        ?Ψ => "\\Psi",
        ?ω => "\\omega",
        ?Ω => "\\Omega",
        ?∅ => "\\emptyset",
        ?∞ => "\\infty",
    }

    OPERATORS = {
        ?⋅     => "cdot",
        ?∗     => "ast",
        ?⋆     => "star",
        ?\\    => "backslash",
        ?×     => "times",
        ?÷     => "div",
        ?⋉     => "ltimes",
        ?⋊     => "rtimes",
        ?⋈     => "bowtie",
        ?∘     => "circ",
        ?⊕     => "oplus",
        ?⊗     => "otimes",
        ?⊙     => "odot",
        ?∑     => "Sigma",
        ?∏     => "Pi",
        ?∧     => "wedge",
        ?⋀     => "bigwedge",
        ?∨     => "vee",
        ?⋁     => "bigvee",
        ?∩     => "cap",
        ?⋂     => "bigcap",
        ?∪     => "cup",
        ?⋃     => "bigcup",
        ?ℵ     => "aleph",
        ?≠     => "neq",
        ?≤     => "leq",
        ?≥     => "geq",
        ?≺     => "prec",
        ?⪯     => "preceq",
        ?≻     => "succ",
        ?⪰     => "succeq",
        ?∈     => "in",
        ?∉     => "notin",
        ?⊂     => "subset",
        ?⊃     => "supset",
        ?⊆     => "subseteq",
        ?⊇     => "supseteq",
        ?≡     => "equiv",
        ?≅     => "cong",
        ?≈     => "approx",
        ?∝     => "propto",
        ?∫     => "int", 
        ?∮     => "oint",
        ?∂     => "partial",
        ?∇     => "nabla",
        ?±     => "pm",
        ?∴     => "therefore",
        ?∵     => "because",
        "..."  => "ldots",
        ?⋯     => "cdots",
        ?⋮     => "vdots",
        ?⋱     => "ddots",
        ?∠     => "angle",
        ?⌢     => "frown",
        ?△     => "triangle",
        ?⋄     => "diamond",
        ?□     => "square",
        ?⌊     => "lfloor",
        ?⌋     => "rfloor",
        ?⌈     => "lceil",
        ?⌉     => "rceil",
        ?ℂ     => "mathbb{C}",
        ?ℕ     => "mathbb{N}",
        ?ℚ     => "mathbb{Q}",
        ?ℝ     => "mathbb{R}",
        ?ℤ     => "mathbb{Z}",
        ?¬     => "neg",
        ?⇒     => "Rightarrow",
        ?⇔     => "Leftrightarrow",
        ?∀     => "forall",
        ?∃     => "exists",
        ?⊥     => "bot",
        ?⊤     => "top",
        ?⊢     => "vdash",
        ?⊨     => "models",
        ?↑     => "uparrow",
        ?↓     => "downarrow",
        ?→     => "rightarrow",
        ?↣     => "rightarrowtail",
        ?↠     => "twoheadrightarrow",
        ?⤖     => "twoheadrightarrowtail",
        ?↦     => "mapsto",
        ?←     => "leftarrow",
        ?↔     => "leftrightarrow",
        ?⇐     => "Leftarrow",
        ?¯     => "widebar",
    }

    PARENS = {
        ?(  => ?(,
        ?)  => ?),
        ?[  => ?[,
        ?]  => ?],
        ?{  => "\\{",
        ?}  => "\\}",
        ?⟨  => "\\langle",
        ?⟩  => "\\rangle",
        ?⌊  => "\\lfloor",
        ?⌋  => "\\rfloor",
        ?⌈  => "\\lceil",
        ?⌉  => "\\rceil",
        ?|  => ?|,
        ?∥  => "\\parallel",
        nil => ?.,
    }

    FONTS = {
        :bold          => "mathbf",
        :double_struck => "mathbb",
        :script        => "mathscr",
        :monospace     => "mathtt",
        :fraktur       => "mathfrak",
        # TODO Implement this
        :sans_serif    => "TODO"
    }

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

    def append(expression, separator = " ")
      # TODO: Remove this when shipping. This is meant for debugging
      puts expression

      case expression
        when Array
          len = expression.length - 1
          expression.each_with_index do |e, i|
             append(e, separator)
             @latex << separator if i != len
          end
        when Hash
          case expression[:type]
            when :operator
                operation(expression[:c])
            when :identifier
              c = expression[:c]

              if CONSTANTS.has_key? c
                  @latex << CONSTANTS[c]
              else
                  append_escaped(c)
              end
            when :number
              @latex << "#{expression[:c]}"
            when :text
              text do
                append_escaped(expression[:c])
              end
            when :paren
              parens(expression[:lparen], expression[:rparen]) do
                append(expression[:e], separator)
              end
            when :font
              font(expression[:operator]) do
                append(expression[:s], separator)
              end
            when :unary
              identifier = expression[:identifier]
              if identifier
                unary(expression[:operator], identifier)
              else
                unary(expression[:operator], expression[:s])
              end
            when :binary
              binary(expression[:operator], expression[:s1], expression[:s2])
            when :ternary
              s1 = expression[:s1]
              s2 = expression[:s2]
              s3 = expression[:s3]
              ternary(expression[:operator], s1, s2, s3)
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

    def method_missing(meth, *args, &block)
      macro(meth, *args, &block)
    end

    def parens(lparen, rparen, &block)
      if lparen || rparen
          @latex << "\\left " << PARENS[lparen] << " "
          yield self
          @latex << " \\right " << PARENS[rparen] 
      else
          yield self
      end
    end

    def font(font, &block)
        macro(FONTS[font], &block)
    end

    def operation(operator, *args)
        if OPERATORS.has_key? operator
            @latex << ?\\ << OPERATORS[operator]
        else
            @latex << operator
        end

        for arg in args do
            @latex << "{ "
            append(arg)
            @latex << " }"
        end
    end

    def unary(operator, s1)
      case operator
      when :sqrt
        sqrt do
          append(s1)
        end
      else
        macro(operator) do
          append(s1)
        end
      end
    end

    def binary(operator, s1, s2)
      case operator
      when :sub
        @latex << "{ "
        append(s1)
        @latex << " }_{ "
        append(s2)
        @latex << " }"
      when :sup
        @latex << "{ "
        append(s1)
        @latex << " }^{ "
        append(s2)
        @latex << " }"
      when :frac
        operation("frac", s1, s2)
      when :root
        sqrt(s1) do
          append(s2)
        end
      when :over
        if not s2.is_a?(Hash)
          raise "Unimplemented"
        end

        case s2[:c]
        when "^"
          hat do
            append(s1)
          end
        when "¯"
          overline do
            append(s1)
          end
        when "→"
          vec do
            append(s1)
          end
        when "."
          dot do
            append(s1)
          end
        when ".."
          ddot do
            append(s1)
          end
        when "⏞"
          overbrace do
            append(s1)
          end
        else
          operation("overset", s1, s2)
        end
      when :under
        if not s2.is_a?(Hash)
          raise "Unimplemented"
        end

        case s2[:c]
        when "_"
          underline do
            append(s1)
          end
        when "⏟"
          underbrace do
            append(s1)
          end
        else
          operation("underset", s1, s2)
        end
      else
        operation(operator, s1, s2)
      end
    end

    def ternary(operator, s1, s2, s3)
      case operator
      when :subsup
        @latex << "{ "
        append(s1)
        @latex << " }_{ "
        append(s2)
        @latex << " }^{ "
        append(s3)
        @latex << " }"
      else
        operation(operator, s1, s2, s3)
      end
    end

    def macro(macro, *args)
      @latex << "\\#{macro}"

      if args.length
        @latex << "["
        append(args, ", ")
        @latex << "]"
      end

      @latex << "{ "

      if block_given?
        yield self if block_given?
      end

      @latex << " }"
    end

    def append_escaped(text)
      text.each_codepoint do |cp|
          if SPECIAL_CHARACTERS.include? cp.chr
          @latex << "\\"
        end
        
        @latex << cp
      end
    end
  end

  class Expression
    def to_latex
      LatexBuilder.new().append_expression(@parsed_expression).to_s
    end
  end
end
