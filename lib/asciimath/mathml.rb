module AsciiMath
  class MathMLBuilder
    def initialize(prefix)
      @prefix = prefix
      @mathml = ''
    end

    def to_s
      @mathml
    end

    def append_expression(expression, attrs = {})
      math('', attrs) do
        append(expression, :single_child => true)
      end
    end

    private

    def mfenced_args(expression)
      args = {}
      args[:open] = expression[:lparen] if expression[:lparen]
      args[:close] = expression[:rparen] if expression[:rparen]
      args[:open] ||= "" if args[:close]
      args[:close] ||= "" if args[:open]
      args
    end

    def append_mtable(expression)
      mtable do
        expression[:rows].each do |row|
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

    def append(expression, opts = {})
      case expression
      when Array
        if expression.length <= 1 || opts[:single_child]
          expression.each { |e| append(e) }
        else
          mrow do
            expression.each { |e| append(e) }
          end
        end
      when Hash
        case expression[:type]
        when :operator
          mo(expression[:c])
        when :identifier
          mi(expression[:c])
        when :number
          mn(expression[:c])
        when :text
          mtext(expression[:c])
        when :paren
          paren = !opts[:strip_paren]
          args = mfenced_args(expression)
          if paren
            if args.empty?
              append(expression[:e], :single_child => true)
            else
              args[:separators] = ""
              if opts[:single_child]
                mfenced(args) do
                  append(expression[:e], :single_child => true)
                end
              else
                mrow do
                  mfenced(args) do
                    append(expression[:e], :single_child => true)
                  end
                end
              end
            end
          else
            append(expression[:e])
          end
        when :font
          style = expression[:operator]
          tag("mstyle", :mathvariant => style.to_s.gsub('_', '-')) do
            append(expression[:s], :single_child => true, :strip_paren => true)
          end
        when :unary
          operator = expression[:operator]
          tag("m#{operator}") do
            append(expression[:s], :single_child => true, :strip_paren => true)
          end
        when :binary
          operator = expression[:operator]
          tag("m#{operator}") do
            append(expression[:s1], :strip_paren => (operator != :sub && operator != :sup))
            append(expression[:s2], :strip_paren => true)
          end
        when :ternary
          operator = expression[:operator]
          tag("m#{operator}") do
            append(expression[:s1])
            append(expression[:s2], :strip_paren => true)
            append(expression[:s3], :strip_paren => true)
          end
        when :matrix
          mrow do
            args = mfenced_args(expression)
            if args.empty?
              append_mtable(expression)
            else
              args[:separators] = ""
              mfenced(args) do
                append_mtable(expression)
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

      @mathml << '<' << @prefix << tag.to_s

      attrs.each_pair do |key, value|
        @mathml << ' ' << key.to_s << '="' << value.to_s << '"'
      end


      if block_given? || text
        @mathml << '>'
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
        yield self if block_given?
        @mathml << '</' << @prefix << tag.to_s << '>'
      else
        @mathml << '/>'
      end
    end
  end

  class Expression
    def to_mathml(prefix = "", attrs = {})
      MathMLBuilder.new(prefix).append_expression(@parsed_expression, attrs).to_s
    end
  end
end
