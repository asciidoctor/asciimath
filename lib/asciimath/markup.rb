require_relative 'ast'
require_relative 'symbol_table'

module AsciiMath
  class MarkupBuilder
    # Operation symbols
    def self.add_default_display_symbols(b)
      b.add(:plus, '+', :operator)
      b.add(:minus, "\u2212", :operator)
      b.add(:cdot, "\u22C5", :operator)
      b.add(:ast, "\u002A", :operator)
      b.add(:star, "\u22C6", :operator)
      b.add(:slash, '/', :operator)
      b.add(:backslash, '\\', :operator)
      b.add(:setminus, '\\', :operator)
      b.add(:times, "\u00D7", :operator)
      b.add(:ltimes, "\u22C9", :operator)
      b.add(:rtimes, "\u22CA", :operator)
      b.add(:bowtie, "\u22C8", :operator)
      b.add(:div, "\u00F7", :operator)
      b.add(:circ, "\u26AC", :operator)
      b.add(:oplus, "\u2295", :operator)
      b.add(:otimes, "\u2297", :operator)
      b.add(:odot, "\u2299", :operator)
      b.add(:sum, "\u2211", :operator, :underover => true)
      b.add(:prod, "\u220F", :operator, :underover => true)
      b.add(:wedge, "\u2227", :operator)
      b.add(:bigwedge, "\u22C0", :operator, :underover => true)
      b.add(:vee, "\u2228", :operator)
      b.add(:bigvee, "\u22C1", :operator, :underover => true)
      b.add(:cap, "\u2229", :operator)
      b.add(:bigcap, "\u22C2", :operator, :underover => true)
      b.add(:cup, "\u222A", :operator)
      b.add(:bigcup, "\u22C3", :operator, :underover => true)

      # Relation symbols
      b.add(:eq, '=', :operator)
      b.add(:ne, "\u2260", :operator)
      b.add(:assign, "\u2254", :operator)
      b.add(:lt, "\u003C", :operator)
      b.add(:gt, "\u003E", :operator)
      b.add(:le, "\u2264", :operator)
      b.add(:ge, "\u2265", :operator)
      b.add(:prec, "\u227A", :operator)
      b.add(:succ, "\u227B", :operator)
      b.add(:preceq, "\u2AAF", :operator)
      b.add(:succeq, "\u2AB0", :operator)
      b.add(:in, "\u2208", :operator)
      b.add(:notin, "\u2209", :operator)
      b.add(:subset, "\u2282", :operator)
      b.add(:supset, "\u2283", :operator)
      b.add(:subseteq, "\u2286", :operator)
      b.add(:supseteq, "\u2287", :operator)
      b.add(:equiv, "\u2261", :operator)
      b.add(:cong, "\u2245", :operator)
      b.add(:approx, "\u2248", :operator)
      b.add(:propto, "\u221D", :operator)

      # Logical symbols
      b.add(:and, 'and', :text)
      b.add(:or, 'or', :text)
      b.add(:not, "\u00AC", :operator)
      b.add(:implies, "\u21D2", :operator)
      b.add(:if, 'if', :operator)
      b.add(:iff, "\u21D4", :operator)
      b.add(:forall, "\u2200", :operator)
      b.add(:exists, "\u2203", :operator)
      b.add(:bot, "\u22A5", :operator)
      b.add(:top, "\u22A4", :operator)
      b.add(:vdash, "\u22A2", :operator)
      b.add(:models, "\u22A8", :operator)

      # Grouping brackets
      b.add(:lparen, '(', :lparen)
      b.add(:rparen, ')', :rparen)
      b.add(:lbracket, '[', :lparen)
      b.add(:rbracket, ']', :rparen)
      b.add(:lbrace, '{', :lparen)
      b.add(:rbrace, '}', :rparen)
      b.add(:vbar, '|', :lrparen)
      b.add(:langle, "\u2329", :lparen)
      b.add(:rangle, "\u232A", :rparen)
      b.add(:parallel, "\u2225", :lrparen)

      # Miscellaneous symbols
      b.add(:integral, "\u222B", :operator)
      b.add(:dx, 'dx', :identifier)
      b.add(:dy, 'dy', :identifier)
      b.add(:dz, 'dz', :identifier)
      b.add(:dt, 'dt', :identifier)
      b.add(:contourintegral, "\u222E", :operator)
      b.add(:partial, "\u2202", :operator)
      b.add(:nabla, "\u2207", :operator)
      b.add(:pm, "\u00B1", :operator)
      b.add(:emptyset, "\u2205", :operator)
      b.add(:infty, "\u221E", :operator)
      b.add(:aleph, "\u2135", :operator)
      b.add(:ellipsis, "\u2026", :operator)
      b.add(:therefore, "\u2234", :operator)
      b.add(:because, "\u2235", :operator)
      b.add(:angle, "\u2220", :operator)
      b.add(:triangle, "\u25B3", :operator)
      b.add(:prime, "\u2032", :operator)
      b.add(:tilde, "~", :accent, :position => :over)
      b.add(:nbsp, "\u00A0", :operator)
      b.add(:frown, "\u2322", :operator)
      b.add(:quad, "\u00A0\u00A0", :operator)
      b.add(:qquad, "\u00A0\u00A0\u00A0\u00A0", :operator)
      b.add(:cdots, "\u22EF", :operator)
      b.add(:vdots, "\u22EE", :operator)
      b.add(:ddots, "\u22F1", :operator)
      b.add(:diamond, "\u22C4", :operator)
      b.add(:square, "\u25A1", :operator)
      b.add(:lfloor, "\u230A", :operator)
      b.add(:rfloor, "\u230B", :operator)
      b.add(:lceiling, "\u2308", :operator)
      b.add(:rceiling, "\u2309", :operator)
      b.add(:dstruck_captial_c, "\u2102", :operator)
      b.add(:dstruck_captial_n, "\u2115", :operator)
      b.add(:dstruck_captial_q, "\u211A", :operator)
      b.add(:dstruck_captial_r, "\u211D", :operator)
      b.add(:dstruck_captial_z, "\u2124", :operator)
      b.add(:f, 'f', :identifier)
      b.add(:g, 'g', :identifier)

      # Standard functions
      b.add(:lim, 'lim', :operator, :underover => true)
      b.add(:Lim, 'Lim', :operator, :underover => true)
      b.add(:min, 'min', :operator, :underover => true)
      b.add(:max, 'max', :operator, :underover => true)
      b.add(:sin, 'sin', :identifier)
      b.add(:Sin, 'Sin', :identifier)
      b.add(:cos, 'cos', :identifier)
      b.add(:Cos, 'Cos', :identifier)
      b.add(:tan, 'tan', :identifier)
      b.add(:Tan, 'Tan', :identifier)
      b.add(:sinh, 'sinh', :identifier)
      b.add(:Sinh, 'Sinh', :identifier)
      b.add(:cosh, 'cosh', :identifier)
      b.add(:Cosh, 'Cosh', :identifier)
      b.add(:tanh, 'tanh', :identifier)
      b.add(:Tanh, 'Tanh', :identifier)
      b.add(:cot, 'cot', :identifier)
      b.add(:Cot, 'Cot', :identifier)
      b.add(:sec, 'sec', :identifier)
      b.add(:Sec, 'Sec', :identifier)
      b.add(:csc, 'csc', :identifier)
      b.add(:Csc, 'Csc', :identifier)
      b.add(:arcsin, 'arcsin', :identifier)
      b.add(:arccos, 'arccos', :identifier)
      b.add(:arctan, 'arctan', :identifier)
      b.add(:coth, 'coth', :identifier)
      b.add(:sech, 'sech', :identifier)
      b.add(:csch, 'csch', :identifier)
      b.add(:exp, 'exp', :identifier)
      b.add(:abs, 'abs', :wrap, :lparen => '|', :rparen => '|')
      b.add(:norm, 'norm', :wrap, :lparen => "\u2225", :rparen => "\u2225")
      b.add(:floor, 'floor', :wrap, :lparen => "\u230A", :rparen => "\u230B")
      b.add(:ceil, 'ceil', :wrap, :lparen => "\u2308", :rparen => "\u2309")
      b.add(:log, 'log', :identifier)
      b.add(:Log, 'Log', :identifier)
      b.add(:ln, 'ln', :identifier)
      b.add(:Ln, 'Ln', :identifier)
      b.add(:det, 'det', :identifier)
      b.add(:dim, 'dim', :identifier)
      b.add(:mod, 'mod', :identifier)
      b.add(:gcd, 'gcd', :identifier)
      b.add(:lcm, 'lcm', :identifier)
      b.add(:lub, 'lub', :identifier)
      b.add(:glb, 'glb', :identifier)

      # Arrows
      b.add(:uparrow, "\u2191", :operator)
      b.add(:downarrow, "\u2193", :operator)
      b.add(:rightarrow, "\u2192", :operator)
      b.add(:to, "\u2192", :operator)
      b.add(:rightarrowtail, "\u21A3", :operator)
      b.add(:twoheadrightarrow, "\u21A0", :operator)
      b.add(:twoheadrightarrowtail, "\u2916", :operator)
      b.add(:mapsto, "\u21A6", :operator)
      b.add(:leftarrow, "\u2190", :operator)
      b.add(:leftrightarrow, "\u2194", :operator)
      b.add(:Rightarrow, "\u21D2", :operator)
      b.add(:Leftarrow, "\u21D0", :operator)
      b.add(:Leftrightarrow, "\u21D4", :operator)

      # Unary tags
      b.add(:sqrt, :sqrt, :sqrt)
      b.add(:cancel, :cancel, :cancel)

      # Binary tags
      b.add(:root, :root, :root)
      b.add(:frac, :frac, :frac)
      b.add(:stackrel, :stackrel, :over)
      b.add(:overset, :overset, :over)
      b.add(:underset, :underset, :under)
      b.add(:color, :color, :color)

      b.add(:sub, "_", :operator)
      b.add(:sup, "^", :operator)
      b.add(:hat, "\u005E", :accent, :position => :over)
      b.add(:overline, "\u00AF", :accent, :position => :over)
      b.add(:vec, "\u2192", :accent, :position => :over)
      b.add(:dot, '.', :accent, :position => :over)
      b.add(:ddot, '..', :accent, :position => :over)
      b.add(:overarc, "\u23DC", :accent, :position => :over)
      b.add(:underline, '_', :accent, :position => :under)
      b.add(:underbrace, "\u23DF", :accent, :position => :under)
      b.add(:overbrace, "\u23DE", :accent, :position => :over)
      b.add(:bold, :bold, :font)
      b.add(:double_struck, :double_struck, :font)
      b.add(:italic, :italic, :font)
      b.add(:bold_italic, :bold_italic, :font)
      b.add(:script, :script, :font)
      b.add(:bold_script, :bold_script, :font)
      b.add(:monospace, :monospace, :font)
      b.add(:fraktur, :fraktur, :font)
      b.add(:bold_fraktur, :bold_fraktur, :font)
      b.add(:sans_serif, :sans_serif, :font)
      b.add(:bold_sans_serif, :bold_sans_serif, :font)
      b.add(:sans_serif_italic, :sans_serif_italic, :font)
      b.add(:sans_serif_bold_italic, :sans_serif_bold_italic, :font)

      # Greek letters
      b.add(:alpha, "\u03b1", :identifier)
      b.add(:Alpha, "\u0391", :identifier)
      b.add(:beta, "\u03b2", :identifier)
      b.add(:Beta, "\u0392", :identifier)
      b.add(:gamma, "\u03b3", :identifier)
      b.add(:Gamma, "\u0393", :operator)
      b.add(:delta, "\u03b4", :identifier)
      b.add(:Delta, "\u0394", :operator)
      b.add(:epsilon, "\u03b5", :identifier)
      b.add(:Epsilon, "\u0395", :identifier)
      b.add(:varepsilon, "\u025b", :identifier)
      b.add(:zeta, "\u03b6", :identifier)
      b.add(:Zeta, "\u0396", :identifier)
      b.add(:eta, "\u03b7", :identifier)
      b.add(:Eta, "\u0397", :identifier)
      b.add(:theta, "\u03b8", :identifier)
      b.add(:Theta, "\u0398", :operator)
      b.add(:vartheta, "\u03d1", :identifier)
      b.add(:iota, "\u03b9", :identifier)
      b.add(:Iota, "\u0399", :identifier)
      b.add(:kappa, "\u03ba", :identifier)
      b.add(:Kappa, "\u039a", :identifier)
      b.add(:lambda, "\u03bb", :identifier)
      b.add(:Lambda, "\u039b", :operator)
      b.add(:mu, "\u03bc", :identifier)
      b.add(:Mu, "\u039c", :identifier)
      b.add(:nu, "\u03bd", :identifier)
      b.add(:Nu, "\u039d", :identifier)
      b.add(:xi, "\u03be", :identifier)
      b.add(:Xi, "\u039e", :operator)
      b.add(:omicron, "\u03bf", :identifier)
      b.add(:Omicron, "\u039f", :identifier)
      b.add(:pi, "\u03c0", :identifier)
      b.add(:Pi, "\u03a0", :operator)
      b.add(:rho, "\u03c1", :identifier)
      b.add(:Rho, "\u03a1", :identifier)
      b.add(:sigma, "\u03c3", :identifier)
      b.add(:Sigma, "\u03a3", :operator)
      b.add(:tau, "\u03c4", :identifier)
      b.add(:Tau, "\u03a4", :identifier)
      b.add(:upsilon, "\u03c5", :identifier)
      b.add(:Upsilon, "\u03a5", :identifier)
      b.add(:phi, "\u03c6", :identifier)
      b.add(:Phi, "\u03a6", :identifier)
      b.add(:varphi, "\u03d5", :identifier)
      b.add(:chi, "\u03c7", :identifier)
      b.add(:Chi, "\u03a7", :identifier)
      b.add(:psi, "\u03c8", :identifier)
      b.add(:Psi, "\u03a8", :identifier)
      b.add(:omega, "\u03c9", :identifier)
      b.add(:Omega, "\u03a9", :operator)

      b
    end

    DEFAULT_DISPLAY_SYMBOL_TABLE = ::AsciiMath::MarkupBuilder.add_default_display_symbols(AsciiMath::SymbolTableBuilder.new).build

    def initialize(symbol_table)
      @symbol_table = symbol_table
    end

    private

    def append(node, opts = {})
      row_mode = opts[:row] || :avoid
      if row_mode == :force
        case node
          when ::AsciiMath::AST::Sequence
            append_row(node)
          else
            append_row([node])
        end
        return
      end

      case node
        when ::AsciiMath::AST::Sequence
          if (node.length <= 1 && row_mode == :avoid) || row_mode == :omit
            node.each { |e| append(e) }
          else
            append_row(node)
          end
        when ::AsciiMath::AST::Group
          append(node.expression)
        when ::AsciiMath::AST::Text
          append_text(node.value)
        when ::AsciiMath::AST::Number
          append_number(node.value)
        when ::AsciiMath::AST::Identifier
          append_identifier(node.value)
        when ::AsciiMath::AST::Symbol
          if (symbol = resolve_symbol(node))
            case symbol[:type]
              when :operator, :accent, :lparen, :rparen, :lrparen
                append_operator(symbol[:value])
              else
                append_identifier(symbol[:value])
            end
          else
            append_identifier(node[:value])
          end
        when ::AsciiMath::AST::Paren
          append_paren(resolve_paren(node.lparen), node.expression, resolve_paren(node.rparen), opts)
        when ::AsciiMath::AST::SubSup
          if (resolve_symbol(node.base_expression) || {})[:underover]
            append_underover(node.base_expression, node.sub_expression, node.sup_expression)
          else
            append_subsup(node.base_expression, node.sub_expression, node.sup_expression)
          end
        when ::AsciiMath::AST::UnaryOp
          if (symbol = resolve_symbol(node.operator))
            case symbol[:type]
              when :identifier
                append_identifier_unary(symbol[:value], node.operand)
              when :operator
                append_operator_unary(symbol[:value], node.operand)
              when :wrap
                append_paren(resolve_paren(symbol[:lparen]), node.operand, resolve_paren(symbol[:rparen]), opts)
              when :accent
                if symbol[:position] == :over
                  append_underover(node.operand, nil, node.operator)
                else
                  append_underover(node.operand, node.operator, nil)
                end
              when :font
                append_font(symbol[:value], node.operand)
              when :cancel
                append_cancel(node.operand)
              when :sqrt
                append_sqrt(node.operand)
            end
          end
        when ::AsciiMath::AST::BinaryOp
          if (symbol = resolve_symbol(node.operator))
            case symbol[:type]
              when :over
                append_underover(node.operand2, nil, node.operand1)
              when :under
                append_underover(node.operand2, node.operand1, nil)
              when :root
                append_root(node.operand2, node.operand1)
              when :color
                append_color(node.operand1.to_hex_rgb, node.operand2)
            end
          end
        when ::AsciiMath::AST::InfixOp
          if (symbol = resolve_symbol(node.operator))
            case symbol[:type]
              when :frac
                append_fraction(node.operand1, node.operand2)
            end
          end
        when ::AsciiMath::AST::Matrix
          append_matrix(resolve_paren(node.lparen), node, resolve_paren(node.rparen))
      end
    end

    def append_row(expressions)
      raise NotImplementedError.new __method__.to_s
    end

    def append_operator(operator)
      raise NotImplementedError.new __method__.to_s
    end

    def append_identifier(identifier)
      raise NotImplementedError.new __method__.to_s
    end

    def append_text(text_string)
      raise NotImplementedError.new __method__.to_s
    end

    def append_number(number)
      raise NotImplementedError.new __method__.to_s
    end

    def append_sqrt(expression)
      raise NotImplementedError.new __method__.to_s
    end

    def append_cancel(expression)
      raise NotImplementedError.new __method__.to_s
    end

    def append_root(base, index)
      raise NotImplementedError.new __method__.to_s
    end

    def append_color(color, expression)
      raise NotImplementedError.new __method__.to_s
    end

    def append_fraction(numerator, denominator)
      raise NotImplementedError.new __method__.to_s
    end

    def append_font(style, expression)
      raise NotImplementedError.new __method__.to_s
    end

    def append_matrix(lparen, rows, rparen)
      raise NotImplementedError.new __method__.to_s
    end

    def append_operator_unary(operator, expression)
      raise NotImplementedError.new __method__.to_s
    end

    def append_identifier_unary(identifier, expression)
      raise NotImplementedError.new __method__.to_s
    end

    def append_paren(lparen, expression, rparen, opts)
      raise NotImplementedError.new __method__.to_s
    end

    def append_subsup(base, sub, sup)
      raise NotImplementedError.new __method__.to_s
    end

    def append_underover(base, under, over)
      raise NotImplementedError.new __method__.to_s
    end

    def resolve_paren(paren_symbol)
      if paren_symbol.nil?
        return nil
      end

      if (resolved = resolve_symbol(paren_symbol))
        resolved[:value]
      else
        case paren_symbol
          when ::AsciiMath::AST::Symbol
            paren_symbol.value
          else
            paren_symbol
        end
      end
    end

    def resolve_symbol(node)
      case node
        when ::AsciiMath::AST::Symbol
          @symbol_table[node.value]
        when ::Symbol
          @symbol_table[node]
        else
          nil
      end
    end
  end
end