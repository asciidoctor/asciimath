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

    alias_method :seq, :expression

    def paren(*args)
      case args.length
        when 1
          lparen = :lparen
          e = args[0]
          rparen = :rparen
        when 3
          lparen = args[0]
          e = args[1]
          rparen = args[2]
        else
          raise "Incorrect argument count #{args.length}"
      end
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
      {:type => :unary, :e => e, :op => operator}
    end

    def binary(operator, e1, e2)
      {:type => :binary, :e1 => e1, :e2 => e2, :op => operator}
    end

    def matrix(*args)
      case args.length
        when 1
          lparen = :lparen
          rows = args[0]
          rparen = :rparen
        when 3
          lparen = args[0]
          rows = args[1]
          rparen = args[2]
        else
          raise "Incorrect argument count #{args.length}"
      end
      {:type => :matrix, :rows => rows, :lparen => lparen, :rparen => rparen}
    end
  end
end