require_relative '../lib/asciimath/ast'

module AsciiMath
  module ASTHelper
    ACTUAL_AST = Class.new do
      include ::AsciiMath::AST
    end.new

    def grseq(*expressions)
      group(seq(*expressions))
    end

    def seq(*expressions)
      mapped = expressions.map { |e| to_ast(e) }
      ACTUAL_AST.expression(*mapped)
    end

    def paren(*args)
      case args.length
        when 1
          lparen = symbol('(')
          e = to_ast(args[0])
          rparen = symbol(')')
        when 3
          lparen = args[0]
          e = to_ast(args[1])
          rparen = args[2]
        else
          raise "Incorrect argument count #{args.length}"
      end
      ACTUAL_AST.paren(lparen, e, rparen)
    end

    def group(*args)
      case args.length
        when 1
          lparen = symbol('(')
          e = to_ast(args[0])
          rparen = symbol(')')
        when 3
          lparen = args[0]
          e = to_ast(args[1])
          rparen = args[2]
        else
          raise "Incorrect argument count #{args.length}"
      end
      ACTUAL_AST.group(lparen, e, rparen)
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

    def infix(e1, operator, e2)
      ACTUAL_AST.infix(to_ast(e1), to_ast(operator), to_ast(e2))
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

    def color(r, g, b, value)
      ACTUAL_AST.color(r, g, b, value)
    end

    def symbol(text)
      symbol = ::AsciiMath::Parser::DEFAULT_PARSER_SYMBOL_TABLE[text]
      if symbol
        ACTUAL_AST.symbol(symbol[:value], text)
      else
        nil
      end
    end

    def matrix(*args)
      case args.length
        when 1
          lparen = symbol('(')
          rows = args[0]
          rparen = symbol(')')
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
          s = symbol(e)
          if s
            s
          elsif e =~ /[0-9]+(.[0-9]+)?/
            number(e)
          elsif e.length > 1
            text(e)
          else
            identifier(e)
          end
        when Symbol
          raise "Not supported"
        when Array
          seq(*e)
        else
          e
      end
    end
  end
end
