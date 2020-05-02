require_relative '../lib/asciimath/ast'

module AsciiMath
  module ASTHelper
    ACTUAL_AST = Class.new do
      include ::AsciiMath::AST
    end.new

    def seq(*expressions)
      ACTUAL_AST.expression(expressions.map { |e| to_ast(e) })
    end

    def paren(*args)
      case args.length
        when 1
          lparen = :lparen
          e = to_ast(args[0])
          rparen = :rparen
        when 3
          lparen = args[0]
          e = to_ast(args[1])
          rparen = args[2]
        else
          raise "Incorrect argument count #{args.length}"
      end
      ACTUAL_AST.paren(lparen, e, rparen)
    end

    def subsup(e, sub, sup)
      ACTUAL_AST.subsup(to_ast(e), to_ast(sub), to_ast(sup))
    end

    def sub(e, sub)
      ACTUAL_AST.sub(to_ast(e), to_ast(sub))
    end

    def sup(e, sup)
      ACTUAL_AST.sup(to_ast(e), to_ast(sup))
    end

    def unary(operator, e)
      ACTUAL_AST.unary(to_ast(operator), to_ast(e))
    end

    def binary(operator, e1, e2)
      ACTUAL_AST.binary(to_ast(operator), to_ast(e1), to_ast(e2))
    end

    def text(value)
      ACTUAL_AST.text(value)
    end

    def identifier(value)
      ACTUAL_AST.identifier(value)
    end

    def number(value)
      ACTUAL_AST.number(value)
    end

    def symbol(value)
      ACTUAL_AST.symbol(value)
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

      rows = rows.map do |row|
        row.map do |col|
          to_ast(col)
        end
      end

      ACTUAL_AST.matrix(lparen, rows, rparen)
    end

    def to_ast(e)
      case e
        when String
          if e =~ /[0-9]+(.[0-9]+)?/
            number(e)
          elsif e.length > 1
            text(e)
          else
            identifier(e)
          end
        when Symbol
          symbol(e)
        when Array
          seq(*e)
        else
          e
      end
    end
  end
end