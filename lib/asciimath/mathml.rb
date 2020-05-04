require_relative 'markup'
require_relative 'symbol_table'

module AsciiMath
  class MathMLBuilder
    include ::AsciiMath::MarkupBuilder

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

    def append_row(expressions)
      mrow do
        expressions.each { |e| append(e) }
      end
    end

    def append_operator(operator)
      mo(operator)
    end

    def append_identifier(identifier)
      mi(identifier)
    end

    def append_text(text)
      mtext(text)
    end

    def append_number(number)
      mn(number)
    end

    def append_sqrt(expression)
      append_tag("sqrt", expression)
    end

    def append_cancel(expression)
      tag("menclose", :notation => "updiagonalstrike") do
        append(expression, :avoid_row => true)
      end
    end

    def append_root(base, index)
      append_tag("root", base, index)
    end

    def append_fraction(numerator, denominator)
      append_tag("frac", numerator, denominator)
    end

    def append_tag(tag, *children)
      tag("m#{tag}") do
        children.each { |child| append(child) }
      end
    end

    def append_font(style, e)
      tag("mstyle", :mathvariant => style.to_s.gsub('_', '-')) do
        append(e)
      end
    end

    def append_color(color, e)
      tag("mstyle", :mathcolor => color[:value]) do
        append(e)
      end
    end

    def append_matrix(lparen, rows, rparen)
      fenced(lparen, rparen) do
        mtable do
          rows.each do |row|
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

    def append_operator_unary(operator, expression)
      mrow do
        mo(operator)
        append(expression, :avoid_row => true)
      end
    end

    def append_identifier_unary(identifier, expression)
      mrow do
        mi(identifier)
        append(expression, :avoid_row => true)
      end
    end

    def append_paren(lparen, e, rparen, opts = {})
      fenced(lparen, rparen) do
        append(e)
      end
    end

    def append_subsup(base, sub, sup)
      if sub && sup
        msubsup do
          append(base)
          append(sub)
          append(sup)
        end
      elsif sub
        msub do
          append(base)
          append(sub)
        end
      elsif sup
        msup do
          append(base)
          append(sup)
        end
      else
        append(base)
      end
    end

    def append_underover(base, sub, sup)
      if sub && sup
        munderover do
          append(base)
          append(sub)
          append(sup)
        end
      elsif sub
        munder do
          append(base)
          append(sub)
        end
      elsif sup
        mover do
          append(base)
          append(sup)
        end
      else
        append(base)
      end
    end

    def method_missing(meth, *args, &block)
      tag(meth, *args, &block)
    end

    def fenced(lparen, rparen)
      if lparen || rparen
        mrow do
          mo(lparen) if lparen
          yield self
          mo(rparen) if rparen
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