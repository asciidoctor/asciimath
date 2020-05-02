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
      ?Γ       => "\\Gamma",
      ?Δ       => "\\Delta",
      ?Θ       => "\\Theta",
      ?Λ       => "\\Lambda",
      ?Ξ       => "\\Xi",
      ?Π       => "\\Pi",
      ?Ω       => "\\Omega",
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
                @latex << (SYMBOLS[op] || "\\#{op.to_s}")

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
      @latex << (SYMBOLS[macro] || "\\#{macro.to_s}")

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
        @latex << "\\left " << (SYMBOLS[lparen] || "\\#{lparen.to_s}") << " "
        yield self
        @latex << " \\right " << (SYMBOLS[rparen] || "\\#{rparen.to_s}")
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
  end

  class Expression
    def to_latex
      LatexBuilder.new().append_expression(ast).to_s
    end
  end
end
