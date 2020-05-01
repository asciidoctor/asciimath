module AsciiMath
  module AST
    def expression(*e)
      case e.length
        when 0
          nil
        when 1
          e[0]
        else
          e
      end
    end

    def paren(lparen, e, rparen, opts = {})
      e = {:type => :paren, :e => e, :lparen => lparen, :rparen => rparen}
      e[:no_unwrap] = opts[:no_unwrap] if opts[:no_unwrap]
      e
    end

    def subsup(e, sub, sup)
      {:type => :subsup, :e => e, :sub => sub, :sup => sup}
    end

    def sub(e, sub)
      subsup(e, sub, nil)
    end

    def sup(e, sup)
      subsup(e, nil, sup)
    end

    def unary(operator, e)
      {:type => :unary, :e => e, :op => operator}
    end

    def binary(operator, e1, e2)
      {:type => :binary, :e1 => e1, :e2 => e2, :op => operator}
    end

    def matrix(lparen, rows, rparen)
      {:type => :matrix, :rows => rows, :lparen => lparen, :rparen => rparen}
    end
  end
end