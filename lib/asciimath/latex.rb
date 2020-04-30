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

    CONSTANTS = {
      ?α => "alpha",
      ?β => "beta",
      ?γ => "gamma",
      ?δ => "delta",
      ?ε => "epsilon",
      ?ɛ => "varepsilon",
      ?ζ => "zeta",
      ?η => "eta",
      ?θ => "theta",
      ?ϑ => "vartheta",
      ?ι => "iota",
      ?κ => "kappa",
      ?λ => "lambda",
      ?μ => "mu",
      ?ν => "nu",
      ?ξ => "xi",
      ?π => "pi",
      ?ρ => "rho",
      ?σ => "sigma",
      ?τ => "tau",
      ?υ => "upsilon",
      ?ϕ => "varphi",
      ?Φ => "Phi",
      ?φ => "phi",
      ?χ => "chi",
      ?ψ => "psi",
      ?Ψ => "Psi",
      ?ω => "omega",
    }

    OPERATORS = {
      ?⋅       => "\\cdot",
      ?∗       => "\\ast",
      ?⋆       => "\\star",
      ?\\      => "\\backslash",
      ?×       => "\\times",
      ?÷       => "\\div",
      ?⋉       => "\\ltimes",
      ?⋊       => "\\rtimes",
      ?⋈       => "\\bowtie",
      ?∘       => "\\circ",
      ?⊕       => "\\oplus",
      ?⊗       => "\\otimes",
      ?⊙       => "\\odot",
      ?∑       => "\\sum",
      ?Σ       => "\\Sigma",
      ?∏       => "\\prod",
      ?∧       => "\\wedge",
      ?⋀       => "\\bigwedge",
      ?∨       => "\\vee",
      ?⋁       => "\\bigvee",
      ?∩       => "\\cap",
      ?⋂       => "\\bigcap",
      ?∪       => "\\cup",
      ?⋃       => "\\bigcup",
      ?∅       => "\\emptyset",
      ?ℵ       => "\\aleph",
      ?∞       => "\\infty",
      ?≠       => "\\neq",
      ?≤       => "\\leq",
      ?≥       => "\\geq",
      ?≺       => "\\prec",
      ?⪯       => "\\preceq",
      ?≻       => "\\succ",
      ?⪰       => "\\succeq",
      ?∈       => "\\in",
      ?∉       => "\\notin",
      ?⊂       => "\\subset",
      ?⊃       => "\\supset",
      ?⊆       => "\\subseteq",
      ?⊇       => "\\supseteq",
      ?≡       => "\\equiv",
      ?≅       => "\\cong",
      ?≈       => "\\approx",
      ?∝       => "\\propto",
      ?∫       => "\\int", 
      ?∮       => "\\oint",
      ?∂       => "\\partial",
      ?∇       => "\\nabla",
      ?±       => "\\pm",
      ?∴       => "\\therefore",
      ?∵       => "\\because",
      "..."    => "\\ldots",
      ?⋯       => "\\cdots",
      ?⋮       => "\\vdots",
      ?⋱       => "\\ddots",
      ?∠       => "\\angle",
      ?⌢       => "\\frown",
      ?△       => "\\triangle",
      ?⋄       => "\\diamond",
      ?□       => "\\square",
      ?⌊       => "\\lfloor",
      ?⌋       => "\\rfloor",
      ?⌈       => "\\lceil",
      ?⌉       => "\\rceil",
      ?ℂ       => "\\mathbb{C}",
      ?ℕ       => "\\mathbb{N}",
      ?ℚ       => "\\mathbb{Q}",
      ?ℝ       => "\\mathbb{R}",
      ?ℤ       => "\\mathbb{Z}",
      ?¬       => "\\neg",
      ?⇒       => "\\Rightarrow",
      ?⇔       => "\\Leftrightarrow",
      ?∀       => "\\forall",
      ?∃       => "\\exists",
      ?⊥       => "\\bot",
      ?⊤       => "\\top",
      ?⊢       => "\\vdash",
      ?⊨       => "\\models",
      ?↑       => "\\uparrow",
      ?↓       => "\\downarrow",
      ?→       => "\\rightarrow",
      ?↣       => "\\rightarrowtail",
      ?↠       => "\\twoheadrightarrow",
      ?⤖       => "\\twoheadrightarrowtail",
      ?↦       => "\\mapsto",
      ?←       => "\\leftarrow",
      ?↔       => "\\leftrightarrow",
      ?⇐       => "\\Leftarrow",
      ?′       => "'",
      ?−       => "-",
      ?Γ       => "Gamma",
      ?Δ       => "Delta",
      ?Θ       => "Theta",
      ?Λ       => "Lambda",
      ?Ξ       => "Xi",
      ?Π       => "Pi",
      ?Ω       => "Omega",
      "lim"    => "\\lim",
      "sin"    => "\\sin",
      "cos"    => "\\cos",
      "tan"    => "\\tan",
      "sec"    => "\\sec",
      "csc"    => "\\csc",
      "cot"    => "\\cot",
      "arcsin" => "\\arcsin",
      "arccos" => "\\arccos",
      "arctan" => "\\arctan",
      "sinh"   => "\\sinh",
      "cosh"   => "\\cosh",
      "tanh"   => "\\tanh",
      "log"    => "\\log",
      "ln"     => "\\ln",
      "det"    => "\\det",
      "dim"    => "\\dim",
      "mod"    => "\\mod",
      "gcd"    => "\\gcd",
      "min"    => "\\min",
      "max"    => "\\max",
      "if"     => "\\text{if}"
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
      :sans_serif    => "mathsf"
    }

    def append(expression, separator = " ")
      case expression
        when Array
          len = expression.length - 1
          expression.each_with_index do |e, i|
            append(e)
            @latex << separator if i != len
          end
        when Hash
          case expression[:type]
            when :operator
              operation(expression[:c])
            when :identifier
              c = expression[:c]

              if CONSTANTS.has_key? c
                @latex << ?\\ << CONSTANTS[c]
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
                if OPERATORS.has_key? identifier
                  @latex << OPERATORS[identifier] << separator
                  append(expression[:s])
                else
                  text do 
                    @latex << identifier
                  end
                  
                  @latex << separator
                  append(expression[:s])
                end
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
        @latex << OPERATORS[operator]
      else
        @latex << operator
      end

      for arg in args do
        @latex << "{"
        append(arg)
        @latex << "}"
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
        sub(s1, s2)
      when :sup
        sup(s1, s2)
      when :frac
        operation("\\frac", s1, s2)
      when :root
        sqrt(s1) do
          append(s2)
        end
      when :over
        if not s2.is_a?(Hash)
          if s1.is_a?(Hash) and s1[:underover]
            sub(s1, s2)
          else
            operation("\\overset", s1, s2)
          end

          return
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
          operation("\\overset", s1, s2)
        end
      when :under
        if not s2.is_a?(Hash)
          if s1.is_a?(Hash) and s1[:underover]
            sub(s1, s2)
          else
            operation("\\underset", s1, s2)
          end

          return
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
          operation("\\underset", s1, s2)
        end
      else
        operation(operator, s1, s2)
      end
    end

    def ternary(operator, s1, s2, s3)
      case operator
      when :subsup, :underover
        @latex << "{" if s1.is_a?(Array)
        append(s1)
        @latex << "}" if s1.is_a?(Array)
        
        @latex << "_"
        
        @latex << "{" if s2.is_a?(Array)
        append(s2)
        @latex << "}" if s2.is_a?(Array)
        
        @latex << "^"
        
        @latex << "{" if s3.is_a?(Array)
        append(s3)
        @latex << "}" if s3.is_a?(Array)
      else
        operation(operator, s1, s2, s3)
      end
    end

    def sub(s1, s2)
      @latex << "{" if s1.is_a?(Array)
      append(s1)
      @latex << "}" if s1.is_a?(Array)
      
      @latex << "_"
      
      @latex << "{" if s2.is_a?(Array)
      append(s2)
      @latex << "}" if s2.is_a?(Array)
    end

    def sup(s1, s2)
      @latex << "{" if s1.is_a?(Array)
      append(s1)
      @latex << "}" if s1.is_a?(Array)
      
      @latex << "^"
      
      @latex << "{" if s2.is_a?(Array)
      append(s2)
      @latex << "}" if s2.is_a?(Array)
    end

    def macro(macro, *args)
      @latex << "\\#{macro}"

      if args.length != 0
        @latex << "["
        append(args, "][")
        @latex << "]"
      end

      @latex << "{"

      if block_given?
        yield self if block_given?
      end

      @latex << "}"
    end

    def append_escaped(text)
      text.each_codepoint do |cp|
        @latex << "\\" if SPECIAL_CHARACTERS.include? cp.chr
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
