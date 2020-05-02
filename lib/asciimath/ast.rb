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

    def paren(lparen, e, rparen)
      {:type => :paren, :e => e, :lparen => lparen, :rparen => rparen}
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
      {:type => :unary, :op => operator, :e => e}
    end

    def binary(operator, e1, e2)
      {:type => :binary, :op => operator, :e1 => e1, :e2 => e2}
    end

    def text(value)
      {:type => :text, :value => value}
    end

    def number(value)
      {:type => :number, :value => value}
    end

    def symbol(value)
      {:type => :symbol, :value => value}
    end

    def identifier(value)
      {:type => :identifier, :value => value}
    end

    def matrix(lparen, rows, rparen)
      {:type => :matrix, :rows => rows, :lparen => lparen, :rparen => rparen}
    end
  end
end