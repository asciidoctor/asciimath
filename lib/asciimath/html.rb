module AsciiMath
  class HTMLBuilder
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
          append(expression, :single_child => true)
        end
      else
        block('', attrs) do
          append(expression, :single_child => true)
        end
      end
    end

    private

    def append(expression, opts = {})
      case expression
        when Array
          row do
            expression.each { |e| append(e) }
          end
        when Hash
          case expression[:type]
            when :operator
              operator(expression[:c])
            when :identifier
              identifier(expression[:c])
            when :number
              number(expression[:c])
            when :text
              text(expression[:c])
            when :paren
              paren = !opts[:strip_paren]
              if paren
                if opts[:single_child]
                  brace(expression[:lparen]) if expression[:lparen]
                  append(expression[:e], :single_child => true)
                  brace(expression[:rparen]) if expression[:rparen]
                else
                  row do
                    brace(expression[:lparen]) if expression[:lparen]
                    append(expression[:e], :single_child => true)
                    brace(expression[:rparen]) if expression[:rparen]
                  end
                end
              else
                append(expression[:e])
              end
            when :font
              #TODO - currently ignored
            when :unary
              operator = expression[:operator]
              tag(operator) do
                append(expression[:s], :single_child => true, :strip_paren => true)
              end
            when :binary
              operator = expression[:operator]
              if operator == :frac
                fraction(expression[:s1],expression[:s2])
              elsif operator == :sub
                subsup(expression[:s1],expression[:s2],nil)
              elsif operator == :sup
                subsup(expression[:s1],nil,expression[:s2])
              elsif operator == :under
                underover(expression[:s1],expression[:s2],nil)
              elsif operator == :over
                underover(expression[:s1],nil,expression[:s2])
              else
                tag(operator) do
                  append(expression[:s1], :strip_paren => true)
                  append(expression[:s2], :strip_paren => true)
                end
              end
            when :ternary
              operator = expression[:operator]
              if operator == :subsup
                subsup(expression[:s1],expression[:s2],expression[:s3])
              elsif operator == :underover
                # TODO: Handle over/under braces in some way? SVG maybe?
                underover(expression[:s1],expression[:s2],expression[:s3])
              end
            when :matrix
              row do
                # TODO: Figure out how big the brace should be and insert something to that effect...
                brace(expression[:lparen]) if expression[:lparen]
                matrix_width  = "grid-template-columns:repeat(" + expression[:rows][0].length.to_s + ",1fr);"
                matrix_height = "grid-template-rows:repeat(" + expression[:rows].length.to_s + ",1fr);"
                
                matrix({:style => (matrixWidth + matrixHeight)}) do
                  expression[:rows].each do |row|
                    row.each do |col|
                      append(col)
                    end
                  end
                end
                brace(expression[:rparen]) if expression[:rparen]
              end
          end
      end
    end
    
    def subsup(base, sub, sup)
      append(base)
      column do
        if sup
          smaller do
            append(sup, :strip_paren => true)
          end
        else
          smaller("&zwj;")
        end
        if sub
          smaller do
            append(sub, :strip_paren => true)
          end
        else
          smaller("&zwj;")
        end
      end
    end
    
    def underover(base, under, over)
      blank("&zwj;")
      column do
        if over
          smaller do
            append(over, :strip_paren => true)
          end
        end
        append(base)
        if under
          smaller do
            append(under, :strip_paren => true)
          end
        end
      end
    end
        
    def fraction(numerator, denominator)
      blank("&zwj;")
      fraction do
        fraction_row do
          fraction_cell do
            smaller do
              row do
                append(numerator, :strip_paren => true)
              end
            end
          end
        end
        fraction_row do
          fraction_cell do
            smaller do
              row do
                append(denominator, :strip_paren => true)
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
        @html << text
        yield if block_given?
        @html << '</span>'
      else
        @html << '/>'
      end
    end
  end

  class Expression
    def to_html(prefix = "", inline = true, attrs = {})
      HTMLBuilder.new(prefix).append_expression(@parsed_expression, inline, attrs).to_s
    end
  end
end