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
          self.row do
            expression.each { |e| append(e) }
          end
        when Hash
          case expression[:type]
            when :operator
              self.operator(expression[:c])
            when :identifier
              self.identifier(expression[:c])
            when :number
              self.number(expression[:c])
            when :text
              self.text(expression[:c])
            when :paren
              paren = !opts[:strip_paren]
              if paren
                if opts[:single_child]
                  self.brace(expression[:lparen]) if expression[:lparen]
                  append(expression[:e], :single_child => true)
                  self.brace(expression[:rparen]) if expression[:rparen]
                else
                  self.row do
                    self.brace(expression[:lparen]) if expression[:lparen]
                    append(expression[:e], :single_child => true)
                    self.brace(expression[:rparen]) if expression[:rparen]
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
              self.row do
                # TODO: Figure out how big the brace should be and insert something to that effect...
                self.brace(expression[:lparen]) if expression[:lparen]
                matrixWidth  = "grid-template-columns:repeat(" + expression[:rows][0].length.to_s + ",1fr);"
                matrixHeight = "grid-template-rows:repeat(" + expression[:rows].length.to_s + ",1fr);"
                
                self.matrix(style: matrixWidth + matrixHeight) do
                  expression[:rows].each do |row|
                    row.each do |col|
                      append(col)
                    end
                  end
                end
                self.brace(expression[:rparen]) if expression[:rparen]
              end
          end
      end
    end
    
    def subsup(base, sub, sup)
      append(base)
      self.column do
        if sup
          self.smaller do
            append(sup, :strip_paren => true)
          end
        else
          self.smaller("&zwj;")
        end
        if sub
          self.smaller do
            append(sub, :strip_paren => true)
          end
        else
          self.smaller("&zwj;")
        end
      end
    end
    
    def underover(base, under, over)
      self.blank("&zwj;")
      self.column do
        if over
          self.smaller do
            append(over, :strip_paren => true)
          end
        end
        append(base)
        if under
          self.smaller do
            append(under, :strip_paren => true)
          end
        end
      end
    end
        
    def fraction(numerator, denominator)
      self.blank("&zwj;")
      self.fraction do
        self.fraction_row do
          self.fraction_cell do
            self.smaller do
              self.row do
                append(numerator, :strip_paren => true)
              end
            end
          end
        end
        self.fraction_row do
          self.fraction_cell do
            self.smaller do
              self.row do
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
        yield self if block_given?
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