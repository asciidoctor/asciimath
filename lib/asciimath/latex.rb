module AsciiMath
  class LatexBuilder
    SPECIAL_CHARACTERS = [?&, ?%, ?$, ?#, ?_, ?{, ?}, ?~, ?^, ?[, ?]]

    CONSTANTS = {
        "α" => "\\alpha",
        "β" => "\\beta",
        "γ" => "\\gamma",
        "Γ" => "\\Gamma",
        "δ" => "\\delta",
        "Δ" => "\\Delta",
        "ε" => "\\epsilon",
        "ɛ" => "\\varepsilon",
        "ζ" => "\\zeta",
        "η" => "\\eta",
        "θ" => "\\theta",
        "Θ" => "\\Theta",
        "ϑ" => "\\vartheta",
        "ι" => "\\iota",
        "κ" => "\\kappa",
        "λ" => "\\lambda",
        "Λ" => "\\Lambda",
        "μ" => "\\mu",
        "ν" => "\\nu",
        "ξ" => "\\xi",
        "Ξ" => "\\Xi",
        "π" => "\\pi",
        "Π" => "\\Pi",
        "ρ" => "\\rho",
        "σ" => "\\sigma",
        "Σ" => "\\Sigma",
        "τ" => "\\tau",
        "υ" => "\\upsilon",
        "ϕ" => "\\phi",
        "Φ" => "\\Phi",
        "φ" => "\\varphi",
        "χ" => "\\chi",
        "ψ" => "\\psi",
        "Ψ" => "\\Psi",
        "ω" => "\\omega",
        "Ω" => "\\Omega",
        "∅" => "\\emptyset",
        "∞" => "\\infty",
        "ℵ" => "\\aleph"
    }

    OPERATORS = {
        "⋅"    => "cdot",
        "∗"    => "ast",
        "⋆"    => "star",
        "\\"   => "backslash",
        "×"    => "times",
        "÷"    => "div",
        "⋉"    => "ltimes",
        "⋊"    => "rtimes",
        "⋈"    => "bowtie",
        "∘"    => "circ",
        "⊕"    => "oplus",
        "⊗"    => "otimes",
        "⊙"    => "odot",
        "∑"    => "Sigma",
        "∏"    => "Pi",
        "∧"    => "wedge",
        "⋀"    => "bidwedge",
        "∨"    => "vee",
        "⋁"    => "bigvee",
        "∩"    => "cap",
        "⋂"    => "bigcap",
        "∪"    => "cup",
        "⋃"    => "bigcup",
        "≠"    => "ne",
        "<"    => "lt",
        ">"    => "gt",
        "≤"    => "le",
        "≥"    => "ge",
        "≺"    => "prec",
        "⪯"    => "preceq",
        "≻"    => "succ",
        "⪰"    => "succeq",
        "∈"    => "in",
        "∉"    => "notin",
        "⊂"    => "subset",
        "⊃"    => "supset",
        "⊆"    => "subseteq",
        "⊇"    => "supseteq",
        "≡"    => "equiv",
        "≅"    => "cong",
        "≈"    => "approx",
        "∝"    => "propto",
        "∫"    => "int", 
        "∮"    => "oint",
        "∂"    => "partial",
        "∇"    => "nabla",
        "±"    => "pm",
        "∴"    => "therefore",
        "∵"    => "because",
        "..."  => "ldots",
        "⋯"    => "cdots",
        "⋮"    => "vdots",
        "⋱"    => "ddots",
        "∠"    => "angle",
        "⌢"    => "frown",
        "△"    => "triangle",
        "⋄"    => "diamond",
        "□"    => "square",
        "⌊"    => "lfloor",
        "⌋"    => "rfloor",
        "⌈"    => "lceiling",
        "⌉"    => "rceiling",
        "ℂ"    => "mathbb{C}",
        "ℕ"    => "mathbb{N}",
        "ℚ"    => "mathbb{Q}",
        "ℝ"    => "mathbb{R}",
        "ℤ"    => "mathbb{Z}",
        "¬"    => "neg",
        "⇒"    => "Rightarrow",
        "⇔"    => "Leftrightarrow",
        "∀"    => "forall",
        "∃"    => "exists",
        "⊥"    => "bot",
        "⊤"    => "top",
        "⊢"    => "vdash",
        "⊨"    => "models",
        "↑"    => "uparrow",
        "↓"    => "downarrow",
        "→"    => "rightarrow",
        "↣"    => "rightarrowtail",
        "↠"    => "twoheadrightarrow",
        "⤖"    => "twoheadrightarrowtail",
        "↦"    => "mapsto",
        "←"    => "leftarrow",
        "↔"    => "leftrightarrow",
        "⇐"    => "Leftarrow",
        "¯"    => "widebar",
        :frac  => "frac",
        :sqrt  => "sqrt",
        :over  => "overset",
        :under => "underset"
    }

    PARENS = {
        "(" => "(",
        ")" => ")",
        "[" => "[",
        "]" => "]",
        "{" => "\\{",
        "}" => "\\}",
        "⟨" => "\\langle",
        "⟩" => "\\rangle",
        "⌊" => "\\lfloor",
        "⌋" => "\\rfloor",
        "⌈" => "\\lceiling",
        "⌉" => "\\rceiling",
        "|" => "|",
        "∥" => "\\parallel",
        nil => "."
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
              operator = expression[:operator]
              if identifier
                operation(expression[:operator], identifier)
              else
                operation(expression[:operator], expression[:s])
              end
            when :binary
              s1 = expression[:s1]
              s2 = expression[:s2]

              if s2.is_a?(Hash) and s2.has_key? :underover
                operation(expression[:operator], s1, s2)
              else
                operation(expression[:operator], s2, s1)
              end
            when :ternary
              operator = expression[:operator]
              s1 = expression[:s1]
              s2 = expression[:s2]
              s2 = expression[:s3]
              operation(expression[:operator], s1, s2, s3)
            when :matrix
              rows = expression[:rows]
              len = rows.length - 1
              
              @latex << "\\begin{matrix} "

              parens(expression[:lparen], expression[:rparen]) do
                rows.each_with_index do |row, i|
                    append(row, " & ")
                    @latex << " \\\\ " if i != len
                end
              end

              @latex << "\\end{matrix}"
          end
      end
    end

    def method_missing(meth, *args, &block)
      macrocall(meth, *args, &block)
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
        macrocall(FONTS[font], &block)
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

    def macrocall(macro, *args)
      text = args.last.is_a?(String) ? args.pop : ''

      @latex << "\\#{macro}{ "

      if block_given? || text
        append_escaped(text)
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
