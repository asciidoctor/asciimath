module AsciiMath
  class MathMLBuilder
    SYMBOLS = {
        # Operation symbols
        :plus => {:value => '+', :type => :operator},
        :minus => {:value => "\u2212", :type => :operator},
        :cdot => {:value => "\u22C5", :type => :operator},
        :ast => {:value => "\u002A", :type => :operator},
        :star => {:value => "\u22C6", :type => :operator},
        :slash => {:value => '/', :type => :operator},
        :backslash => {:value => '\\', :type => :operator},
        :setminus => {:value => '\\', :type => :operator},
        :times => {:value => "\u00D7", :type => :operator},
        :ltimes => {:value => "\u22C9", :type => :operator},
        :rtimes => {:value => "\u22CA", :type => :operator},
        :bowtie => {:value => "\u22C8", :type => :operator},
        :div => {:value => "\u00F7", :type => :operator},
        :circ => {:value => "\u26AC", :type => :operator},
        :oplus => {:value => "\u2295", :type => :operator},
        :otimes => {:value => "\u2297", :type => :operator},
        :odot => {:value => "\u2299", :type => :operator},
        :sum => {:value => "\u2211", :type => :operator, :underover => true},
        :prod => {:value => "\u220F", :type => :operator, :underover => true},
        :wedge => {:value => "\u2227", :type => :operator},
        :bigwedge => {:value => "\u22C0", :type => :operator, :underover => true},
        :vee => {:value => "\u2228", :type => :operator},
        :bigvee => {:value => "\u22C1", :type => :operator, :underover => true},
        :cap => {:value => "\u2229", :type => :operator},
        :bigcap => {:value => "\u22C2", :type => :operator, :underover => true},
        :cup => {:value => "\u222A", :type => :operator},
        :bigcup => {:value => "\u22C3", :type => :operator, :underover => true},

        # Relation symbols
        :eq => {:value => '=', :type => :operator},
        :ne => {:value => "\u2260", :type => :operator},
        :assign => {:value => "\u2254", :type => :operator},
        :lt => {:value => "\u003C", :type => :operator},
        :gt => {:value => "\u003E", :type => :operator},
        :le => {:value => "\u2264", :type => :operator},
        :ge => {:value => "\u2265", :type => :operator},
        :prec => {:value => "\u227A", :type => :operator},
        :succ => {:value => "\u227B", :type => :operator},
        :preceq => {:value => "\u2AAF", :type => :operator},
        :succeq => {:value => "\u2AB0", :type => :operator},
        :in => {:value => "\u2208", :type => :operator},
        :notin => {:value => "\u2209", :type => :operator},
        :subset => {:value => "\u2282", :type => :operator},
        :supset => {:value => "\u2283", :type => :operator},
        :subseteq => {:value => "\u2286", :type => :operator},
        :supseteq => {:value => "\u2287", :type => :operator},
        :equiv => {:value => "\u2261", :type => :operator},
        :cong => {:value => "\u2245", :type => :operator},
        :approx => {:value => "\u2248", :type => :operator},
        :propto => {:value => "\u221D", :type => :operator},

        # Logical symbols
        :and => {:value => 'and', :type => :text},
        :or => {:value => 'or', :type => :text},
        :not => {:value => "\u00AC", :type => :operator},
        :implies => {:value => "\u21D2", :type => :operator},
        :if => {:value => 'if', :type => :operator},
        :iff => {:value => "\u21D4", :type => :operator},
        :forall => {:value => "\u2200", :type => :operator},
        :exists => {:value => "\u2203", :type => :operator},
        :bot => {:value => "\u22A5", :type => :operator},
        :top => {:value => "\u22A4", :type => :operator},
        :vdash => {:value => "\u22A2", :type => :operator},
        :models => {:value => "\u22A8", :type => :operator},

        # Grouping brackets
        :lparen => {:value => '(', :type => :lparen},
        :rparen => {:value => ')', :type => :rparen},
        :lbracket => {:value => '[', :type => :lparen},
        :rbracket => {:value => ']', :type => :rparen},
        :lbrace => {:value => '{', :type => :lparen},
        :rbrace => {:value => '}', :type => :rparen},
        :vbar => {:value => '|', :type => :lrparen},
        :langle => {:value => "\u2329", :type => :lparen},
        :rangle => {:value => "\u232A", :type => :rparen},
        :parallel => {:value => "\u2225", :type => :lrparen},

        # Miscellaneous symbols
        :integral => {:value => "\u222B", :type => :operator},
        :dx => {:value => 'dx', :type => :identifier},
        :dy => {:value => 'dy', :type => :identifier},
        :dz => {:value => 'dz', :type => :identifier},
        :dt => {:value => 'dt', :type => :identifier},
        :contourintegral => {:value => "\u222E", :type => :operator},
        :partial => {:value => "\u2202", :type => :operator},
        :nabla => {:value => "\u2207", :type => :operator},
        :pm => {:value => "\u00B1", :type => :operator},
        :emptyset => {:value => "\u2205", :type => :operator},
        :infty => {:value => "\u221E", :type => :operator},
        :aleph => {:value => "\u2135", :type => :operator},
        :ellipsis => {:value => "\u2026", :type => :operator},
        :therefore => {:value => "\u2234", :type => :operator},
        :because => {:value => "\u2235", :type => :operator},
        :angle => {:value => "\u2220", :type => :operator},
        :triangle => {:value => "\u25B3", :type => :operator},
        :prime => {:value => "\u2032", :type => :operator},
        :tilde => {:value => "~", :type => :accent, :position => :over},
        :nbsp => {:value => "\u00A0", :type => :operator},
        :frown => {:value => "\u2322", :type => :operator},
        :quad => {:value => "\u00A0\u00A0", :type => :operator},
        :qquad => {:value => "\u00A0\u00A0\u00A0\u00A0", :type => :operator},
        :cdots => {:value => "\u22EF", :type => :operator},
        :vdots => {:value => "\u22EE", :type => :operator},
        :ddots => {:value => "\u22F1", :type => :operator},
        :diamond => {:value => "\u22C4", :type => :operator},
        :square => {:value => "\u25A1", :type => :operator},
        :lfloor => {:value => "\u230A", :type => :operator},
        :rfloor => {:value => "\u230B", :type => :operator},
        :lceiling => {:value => "\u2308", :type => :operator},
        :rceiling => {:value => "\u2309", :type => :operator},
        :dstruck_captial_c => {:value => "\u2102", :type => :operator},
        :dstruck_captial_n => {:value => "\u2115", :type => :operator},
        :dstruck_captial_q => {:value => "\u211A", :type => :operator},
        :dstruck_captial_r => {:value => "\u211D", :type => :operator},
        :dstruck_captial_z => {:value => "\u2124", :type => :operator},
        :f => {:value => 'f', :type => :identifier},
        :g => {:value => 'g', :type => :identifier},


        # Standard functions
        :lim => {:value => 'lim', :type => :operator, :underover => true},
        :Lim => {:value => 'Lim', :type => :operator, :underover => true},
        :min => {:value => 'min', :type => :operator, :underover => true},
        :max => {:value => 'max', :type => :operator, :underover => true},
        :sin => {:value => 'sin', :type => :identifier},
        :Sin => {:value => 'Sin', :type => :identifier},
        :cos => {:value => 'cos', :type => :identifier},
        :Cos => {:value => 'Cos', :type => :identifier},
        :tan => {:value => 'tan', :type => :identifier},
        :Tan => {:value => 'Tan', :type => :identifier},
        :sinh => {:value => 'sinh', :type => :identifier},
        :Sinh => {:value => 'Sinh', :type => :identifier},
        :cosh => {:value => 'cosh', :type => :identifier},
        :Cosh => {:value => 'Cosh', :type => :identifier},
        :tanh => {:value => 'tanh', :type => :identifier},
        :Tanh => {:value => 'Tanh', :type => :identifier},
        :cot => {:value => 'cot', :type => :identifier},
        :Cot => {:value => 'Cot', :type => :identifier},
        :sec => {:value => 'sec', :type => :identifier},
        :Sec => {:value => 'Sec', :type => :identifier},
        :csc => {:value => 'csc', :type => :identifier},
        :Csc => {:value => 'Csc', :type => :identifier},
        :arcsin => {:value => 'arcsin', :type => :identifier},
        :arccos => {:value => 'arccos', :type => :identifier},
        :arctan => {:value => 'arctan', :type => :identifier},
        :coth => {:value => 'coth', :type => :identifier},
        :sech => {:value => 'sech', :type => :identifier},
        :csch => {:value => 'csch', :type => :identifier},
        :exp => {:value => 'exp', :type => :identifier},
        :abs => {:value => 'abs', :type => :wrap, :lparen => '|', :rparen => '|'},
        :norm => {:value => 'norm', :type => :wrap, :lparen => "\u2225", :rparen => "\u2225"},
        :floor => {:value => 'floor', :type => :wrap, :lparen => "\u230A", :rparen => "\u230B"},
        :ceil => {:value => 'ceil', :type => :wrap, :lparen => "\u2308", :rparen => "\u2309"},
        :log => {:value => 'log', :type => :identifier},
        :Log => {:value => 'Log', :type => :identifier},
        :ln => {:value => 'ln', :type => :identifier},
        :Ln => {:value => 'Ln', :type => :identifier},
        :det => {:value => 'det', :type => :identifier},
        :dim => {:value => 'dim', :type => :identifier},
        :mod => {:value => 'mod', :type => :identifier},
        :gcd => {:value => 'gcd', :type => :identifier},
        :lcm => {:value => 'lcm', :type => :identifier},
        :lub => {:value => 'lub', :type => :identifier},
        :glb => {:value => 'glb', :type => :identifier},

        # Arrows
        :uparrow => {:value => "\u2191", :type => :operator},
        :downarrow => {:value => "\u2193", :type => :operator},
        :rightarrow => {:value => "\u2192", :type => :operator},
        :to => {:value => "\u2192", :type => :operator},
        :rightarrowtail => {:value => "\u21A3", :type => :operator},
        :twoheadrightarrow => {:value => "\u21A0", :type => :operator},
        :twoheadrightarrowtail => {:value => "\u2916", :type => :operator},
        :mapsto => {:value => "\u21A6", :type => :operator},
        :leftarrow => {:value => "\u2190", :type => :operator},
        :leftrightarrow => {:value => "\u2194", :type => :operator},
        :Rightarrow => {:value => "\u21D2", :type => :operator},
        :Leftarrow => {:value => "\u21D0", :type => :operator},
        :Leftrightarrow => {:value => "\u21D4", :type => :operator},

        # Other
        :sqrt => {:value => :sqrt, :type => :tag},
        :root => {:value => :root, :type => :tag},
        :frac => {:value => :frac, :type => :tag},
        :stackrel => {:value => :over, :type => :tag, :switch_operands => true},
        :overset => {:value => :over, :type => :tag, :switch_operands => true},
        :underset => {:value => :under, :type => :tag, :switch_operands => true},
        :sub => {:value => "_", :type => :operator},
        :sup => {:value => "^", :type => :operator},
        :hat => {:value => "\u005E", :type => :accent, :position => :over},
        :overline => {:value => "\u00AF", :type => :accent, :position => :over},
        :vec => {:value => "\u2192", :type => :accent, :position => :over},
        :dot => {:value => '.', :type => :accent, :position => :over},
        :ddot => {:value => '..', :type => :accent, :position => :over},
        :overarc => {:value => "\u23DC", :type => :accent, :position => :over},
        :underline => {:value => '_', :type => :accent, :position => :under},
        :underbrace => {:value => "\u23DF", :type => :accent, :position => :under},
        :overbrace => {:value => "\u23DE", :type => :accent, :position => :over},

        :bold => {:value => :bold, :type => :font},
        :double_struck => {:value => :double_struck, :type => :font},
        :italic => {:value => :italic, :type => :font},
        :bold_italic => {:value => :bold_italic, :type => :font},
        :script => {:value => :script, :type => :font},
        :bold_script => {:value => :bold_script, :type => :font},
        :monospace => {:value => :monospace, :type => :font},
        :fraktur => {:value => :fraktur, :type => :font},
        :bold_fraktur => {:value => :bold_fraktur, :type => :font},
        :sans_serif => {:value => :sans_serif, :type => :font},
        :bold_sans_serif => {:value => :bold_sans_serif, :type => :font},
        :sans_serif_italic => {:value => :sans_serif_italic, :type => :font},
        :sans_serif_bold_italic => {:value => :sans_serif_bold_italic, :type => :font},

        # Greek letters
        :alpha => {:value => "\u03b1", :type => :identifier},
        :Alpha => {:value => "\u0391", :type => :identifier},
        :beta => {:value => "\u03b2", :type => :identifier},
        :Beta => {:value => "\u0392", :type => :identifier},
        :gamma => {:value => "\u03b3", :type => :identifier},
        :Gamma => {:value => "\u0393", :type => :operator},
        :delta => {:value => "\u03b4", :type => :identifier},
        :Delta => {:value => "\u0394", :type => :operator},
        :epsilon => {:value => "\u03b5", :type => :identifier},
        :Epsilon => {:value => "\u0395", :type => :identifier},
        :varepsilon => {:value => "\u025b", :type => :identifier},
        :zeta => {:value => "\u03b6", :type => :identifier},
        :Zeta => {:value => "\u0396", :type => :identifier},
        :eta => {:value => "\u03b7", :type => :identifier},
        :Eta => {:value => "\u0397", :type => :identifier},
        :theta => {:value => "\u03b8", :type => :identifier},
        :Theta => {:value => "\u0398", :type => :operator},
        :vartheta => {:value => "\u03d1", :type => :identifier},
        :iota => {:value => "\u03b9", :type => :identifier},
        :Iota => {:value => "\u0399", :type => :identifier},
        :kappa => {:value => "\u03ba", :type => :identifier},
        :Kappa => {:value => "\u039a", :type => :identifier},
        :lambda => {:value => "\u03bb", :type => :identifier},
        :Lambda => {:value => "\u039b", :type => :operator},
        :mu => {:value => "\u03bc", :type => :identifier},
        :Mu => {:value => "\u039c", :type => :identifier},
        :nu => {:value => "\u03bd", :type => :identifier},
        :Nu => {:value => "\u039d", :type => :identifier},
        :xi => {:value => "\u03be", :type => :identifier},
        :Xi => {:value => "\u039e", :type => :operator},
        :omicron => {:value => "\u03bf", :type => :identifier},
        :Omicron => {:value => "\u039f", :type => :identifier},
        :pi => {:value => "\u03c0", :type => :identifier},
        :Pi => {:value => "\u03a0", :type => :operator},
        :rho => {:value => "\u03c1", :type => :identifier},
        :Rho => {:value => "\u03a1", :type => :identifier},
        :sigma => {:value => "\u03c3", :type => :identifier},
        :Sigma => {:value => "\u03a3", :type => :operator},
        :tau => {:value => "\u03c4", :type => :identifier},
        :Tau => {:value => "\u03a4", :type => :identifier},
        :upsilon => {:value => "\u03c5", :type => :identifier},
        :Upsilon => {:value => "\u03a5", :type => :identifier},
        :phi => {:value => "\u03c6", :type => :identifier},
        :Phi => {:value => "\u03a6", :type => :identifier},
        :varphi => {:value => "\u03d5", :type => :identifier},
        :chi => {:value => "\u03c7", :type => :identifier},
        :Chi => {:value => "\u03a7", :type => :identifier},
        :psi => {:value => "\u03c8", :type => :identifier},
        :Psi => {:value => "\u03a8", :type => :identifier},
        :omega => {:value => "\u03c9", :type => :identifier},
        :Omega => {:value => "\u03a9", :type => :operator},
    }

    def initialize(prefix)
      @prefix = prefix
      @mathml = ''
    end

    def to_s
      @mathml
    end

    def append_expression(expression, attrs = {})
      math('', attrs) do
        append(expression, :avoid_row => true)
      end
    end

    private

    NUMBER = /[0-9]+(?:\.[0-9]+)?/

    def append(expression, opts = {})
      case expression
        when String
          if expression =~ NUMBER
            mn(expression)
          elsif expression.length > 1
            mtext(expression)
          else
            mi(expression)
          end
        when Symbol
          if (symbol = SYMBOLS[expression])
            case symbol[:type]
              when :operator
                mo(symbol[:value])
              else
                mi(symbol[:value])
            end
          else
            mi(expression)
          end
        when Array
          if expression.length <= 1 || opts[:avoid_row]
            expression.each { |e| append(e) }
          else
            mrow do
              expression.each { |e| append(e) }
            end
          end
        when Hash
          case expression[:type]
            when :paren
              fenced(expression[:lparen], expression[:rparen]) do
                append(expression[:e])
              end
            when :subsup
              sub = expression[:sub]
              sup = expression[:sup]
              if (SYMBOLS[expression[:e]] || {})[:underover]
                if sub && sup
                  munderover do
                    append(expression[:e])
                    append(sub)
                    append(sup)
                  end
                elsif sub
                  munder do
                    append(expression[:e])
                    append(sub)
                  end
                elsif sup
                  mover do
                    append(expression[:e])
                    append(sup)
                  end
                else
                  append(expression[:e])
                end
              else
                if sub && sup
                  msubsup do
                    append(expression[:e])
                    append(sub)
                    append(sup)
                  end
                elsif sub
                  msub do
                    append(expression[:e])
                    append(sub)
                  end
                elsif sup
                  msup do
                    append(expression[:e])
                    append(sup)
                  end
                else
                  append(expression[:e])
                end
              end
            when :unary
              if (symbol = SYMBOLS[expression[:op]])
                case symbol[:type]
                  when :identifier
                    mrow do
                      mi(symbol[:value])
                      append(expression[:e], :avoid_row => true)
                    end
                  when :operator
                    mrow do
                      mo(symbol[:value])
                      append(expression[:e], :avoid_row => true)
                    end
                  when :wrap
                    fenced(symbol[:lparen], symbol[:rparen]) do
                      append(expression[:e])
                    end
                  when :accent
                    if symbol[:position] == :over
                      mover do
                        append(expression[:e])
                        mo(symbol[:value])
                      end
                    else
                      munder do
                        append(expression[:e])
                        mo(symbol[:value])
                      end
                    end
                  when :font
                    style = symbol[:value]
                    tag("mstyle", :mathvariant => style.to_s.gsub('_', '-')) do
                      append(expression[:e])
                    end
                  when :tag
                    tag("m#{symbol[:value]}") do
                      append(expression[:e])
                    end
                end
              end
            when :binary
              if (symbol = SYMBOLS[expression[:op]])
                case symbol[:type]
                  when :tag
                    tag("m#{symbol[:value]}") do
                      if symbol[:switch_operands]
                        append(expression[:e2])
                        append(expression[:e1])
                      else
                        append(expression[:e1])
                        append(expression[:e2])
                      end
                    end
                end
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

    def fenced(lparen, rparen, &block)
      if lparen || rparen
        mfenced(:open => resolve(lparen) || '', :close => resolve(rparen) || '') do
          yield self
        end
      else
        yield self
      end
    end

    def tag(tag, *args)
      attrs = args.last.is_a?(Hash) ? args.pop : {}
      text = args.last.is_a?(String) || args.last.is_a?(Symbol) ? args.pop.to_s : ''

      @mathml << '<' << @prefix << tag.to_s

      attrs.each_pair do |key, value|
        @mathml << ' ' << key.to_s << '="'
        append_escaped(value.to_s)
        @mathml << '"'
      end


      if block_given? || text
        @mathml << '>'
        append_escaped(text)
        yield self if block_given?
        @mathml << '</' << @prefix << tag.to_s << '>'
      else
        @mathml << '/>'
      end
    end

    def resolve(symbol)
      if symbol.nil?
        nil
      elsif (resolved = SYMBOLS[symbol])
        resolved[:value]
      else
        symbol
      end
    end

    def append_escaped(text)
      text.each_codepoint do |cp|
        if cp == 38
          @mathml << "&amp;"
        elsif cp == 60
          @mathml << "&lt;"
        elsif cp == 62
          @mathml << "&gt;"
        elsif cp > 127
          @mathml << "&#x#{cp.to_s(16).upcase};"
        else
          @mathml << cp
        end
      end
    end
  end

  class Expression
    def to_mathml(prefix = "", attrs = {})
      MathMLBuilder.new(prefix).append_expression(ast, attrs).to_s
    end
  end
end