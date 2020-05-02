require_relative 'markup'

module AsciiMath
  class HTMLBuilder
    include ::AsciiMath::MarkupBuilder

    def initialize(prefix)
      @prefix = prefix
      @html = ''
    end

    def to_s
      @html
    end

    def append_expression(expression, inline, attrs = {})
      if inline
        inline('', attrs) do
          append(expression, :avoid_row => true)
        end
      else
        block('', attrs) do
          append(expression, :avoid_row => true)
        end
      end
    end

    private

    ZWJ = "\u200D"

    def append_row(expressions)
      row do
        expressions.each { |e| append(e) }
      end
    end

    def append_operator(operator)
      operator(operator)
    end

    def append_identifier(identifier)
      identifier(identifier)
    end

    def append_text(text)
      text(text)
    end

    def append_number(number)
      number(number)
    end

    def append_sqrt(expression)
      tag("sqrt") do
        append(child, :avoid_row => true)
      end
    end

    def append_root(base, index)
      tag("sqrt") do
        append(base)
        append(index)
      end
    end

    def append_font(style, e)
      #TODO - currently ignored
      append(e)
    end

    def append_matrix(lparen, rows, rparen)
      row do
        # Figures out a font size for the braces, based on the height of the matrix.
        # NOTE: This does not currently consider the size of each element within the matrix.
        brace_height = "font-size: " + rows.length.to_s + "00%;"

        if lparen
          brace(lparen, {:style => brace_height})
        else
          blank(ZWJ)
        end
        matrix_width = "grid-template-columns:repeat(" + rows[0].length.to_s + ",1fr);"
        matrix_height = "grid-template-rows:repeat(" + rows.length.to_s + ",1fr);"

        matrix({:style => (matrix_width + matrix_height)}) do
          rows.each do |row|
            row.each do |col|
              row do
                append(col)
              end
            end
          end
        end
        if rparen
          brace(rparen, {:style => brace_height})
        else
          blank(ZWJ)
        end
      end
    end

    def append_operator_unary(operator, expression)
      tag(operator) do
        append(expression, :avoid_row => true)
      end
    end

    def append_identifier_unary(identifier, expression)
      row do
        identifier(identifier)
        append(expression, :avoid_row => true)
      end
    end

    def append_paren(lparen, e, rparen, opts = {})
      if opts[:avoid_row]
        brace(lparen) if lparen
        append(e, :avoid_row => true)
        brace(rparen) if rparen
      else
        row do
          brace(lparen) if lparen
          append(e, :avoid_row => true)
          brace(rparen) if rparen
        end
      end
    end

    def append_subsup(base, sub, sup)
      append(base)
      subsup do
        if sup
          smaller do
            append(sup)
          end
        else
          smaller(ZWJ)
        end
        if sub
          smaller do
            append(sub)
          end
        else
          smaller(ZWJ)
        end
      end
    end

    def append_underover(base, under, over)
      # TODO: Handle over/under braces in some way? SVG maybe?
      blank(ZWJ)
      underover do
        smaller do
          if over
            append(over)
          else
            blank(ZWJ)
          end
        end
        append(base)
        smaller do
          if under
            append(under)
          else
            blank(ZWJ)
          end
        end
      end
    end

    def append_fraction(numerator, denominator)
      blank(ZWJ)
      fraction do
        fraction_row do
          fraction_cell do
            smaller do
              row do
                append(numerator)
              end
            end
          end
        end
        fraction_row do
          fraction_cell do
            smaller do
              row do
                append(denominator)
              end
            end
          end
        end
      end
    end

    def method_missing(meth, *args, &block)
      tag(meth, *args, &block)
    end

    def tag(tag, *args)
      attrs = args.last.is_a?(Hash) ? args.pop : {}
      text = args.last.is_a?(String) ? args.pop : ''

      @html << '<span class="math-' << @prefix << tag.to_s << '"'

      attrs.each_pair do |key, value|
        @html << ' ' << key.to_s << '="' << value.to_s << '"'
      end

      if block_given? || text
        @html << '>'
        text.each_codepoint do |cp|
          if cp == 38
            @html << "&amp;"
          elsif cp == 60
            @html << "&lt;"
          elsif cp == 62
            @html << "&gt;"
          elsif cp > 127
            @html << "&#x#{cp.to_s(16).upcase};"
          else
            @html << cp
          end
        end
        yield if block_given?
        @html << '</span>'
      else
        @html << '/>'
      end
    end
  end

  class Expression
    def to_html(prefix = "", inline = true, attrs = {})
      HTMLBuilder.new(prefix).append_expression(ast, inline, attrs).to_s
    end
  end
end
