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
        "⋅"   => "\\cdot",
        "∗"   => "\\ast",
        "⋆"   => "\\star",
        "\\"  => "\\backslash",
        "×"   => "\\times",
        "÷"   => "\\div",
        "⋉"   => "\\ltimes",
        "⋊"   => "\\rtimes",
        "⋈"   => "\\bowtie",
        "∘"   => "\\circ",
        "⊕"   => "\\oplus",
        "⊗"   => "\\otimes",
        "⊙"   => "\\odot",
        "∑"   => "\\Sigma",
        "∏"   => "\\Pi",
        "∧"   => "\\wedge",
        "⋀"   => "\\bidwedge",
        "∨"   => "\\vee",
        "⋁"   => "\\bigvee",
        "∩"   => "\\cap",
        "⋂"   => "\\bigcap",
        "∪"   => "\\cup",
        "⋃"   => "\\bigcup",
        "≠"   => "\\ne",
        "<"   => "\\lt",
        ">"   => "\\gt",
        "≤"   => "\\le",
        "≥"   => "\\ge",
        "≺"   => "\\prec",
        "⪯"   => "\\preceq",
        "≻"   => "\\succ",
        "⪰"   => "\\succeq",
        "∈"   => "\\in",
        "∉"   => "\\notin",
        "⊂"   => "\\subset",
        "⊃"   => "\\supset",
        "⊆"   => "\\subseteq",
        "⊇"   => "\\supseteq",
        "≡"   => "\\equiv",
        "≅"   => "\\cong",
        "≈"   => "\\approx",
        "∝"   => "\\propto",
        "∫"   => "\\int", 
        "∮"   => "\\oint",
        "∂"   => "\\partial",
        "∇"   => "\\nabla",
        "±"   => "\\pm",
        "∴"   => "\\therefore",
        "∵"   => "\\because",
        "..." => "\\ldots",
        "⋯"   => "\\cdots",
        "⋮"   => "\\vdots",
        "⋱"   => "\\ddots",
        "∠"   => "\\angle",
        "⌢"   => "\\frown",
        "△"   => "\\triangle",
        "⋄"   => "\\diamond",
        "□"   => "\\square",
        "⌊"   => "\\lfloor",
        "⌋"   => "\\rfloor",
        "⌈"   => "\\lceiling",
        "⌉"   => "\\rceiling",
        "ℂ"   => "\\mathbb{C}",
        "ℕ"   => "\\mathbb{N}",
        "ℚ"   => "\\mathbb{Q}",
        "ℝ"   => "\\mathbb{R}",
        "ℤ"   => "\\mathbb{Z}",
        "¬"   => "\\neg",
        "⇒"   => "\\Rightarrow",
        "⇔"   => "\\Leftrightarrow",
        "∀"   => "\\forall",
        "∃"   => "\\exists",
        "⊥"   => "\\bot",
        "⊤"   => "\\top",
        "⊢"   => "\\vdash",
        "⊨"   => "\\models"
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
        "∥" =>"\\parallel",
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

    def append_expression(expression, attrs = {})
      tag("math") do
        append(expression, :avoid_row => true)
      end
    end

    private

    def append(expression, opts = {})
      puts expression

      case expression
        when Array
          len = expression.length - 1
          expression.each_with_index do |e, i| 
             append(e)
             @latex << " " if i != len
          end
        when Hash
          case expression[:type]
            when :operator
              c = expression[:c]

              if OPERATORS.has_key? c
                  @latex << OPERATORS[c]
              else
                  @latex << c
              end

              @latex << " "
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
                append(expression[:e])
              end
            when :font
              font(expression[:operator]) do
                append(expression[:s])
              end
            when :unary
              identifier = expression[:identifier]
              operator = expression[:operator]
              if identifier
                mrow do
                  mi(identifier)
                  append(expression[:s], :avoid_row => true)
                end
              else
                tag("m#{operator}") do
                  append(expression[:s])
                end
              end
            when :binary
              operator = expression[:operator]
              tag("m#{operator}") do
                append(expression[:s1])
                append(expression[:s2])
              end
            when :ternary
              operator = expression[:operator]
              tag("m#{operator}") do
                append(expression[:s1])
                append(expression[:s2])
                append(expression[:s3])
              end
            when :matrix
              fenced(expression[:lparen], expression[:rparen]) do
                mtable do
                  expression[:rows].each do |row|
                    mtr do
                      row.each do |col|
                        mtd do
                          append(col)
                        end
                      end
                    end
                  end
                end
              end
          end
      end
    end

    def method_missing(meth, *args, &block)
      tag(meth, *args, &block)
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
        tag(FONTS[font], &block)
    end

    def fenced(lparen, rparen, &block)
      if lparen || rparen
        mfenced(:open => lparen || '', :close => rparen || '') do
          yield self
        end
      else
        yield self
      end
    end

    def tag(tag, *args)
      text = args.last.is_a?(String) ? args.pop : ''

      @latex << "\\#{tag}{ "

      if block_given? || text
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
    def to_latex(attrs = {})
      LatexBuilder.new().append_expression(@parsed_expression, attrs).to_s
    end
  end
end
