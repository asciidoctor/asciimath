module AsciiMath
  module AST
    def expression(*e)
      case e.length
        when 0
          nil
        when 1
          e[0]
        else
          Sequence.new(e)
      end
    end

    def paren(lparen, e, rparen)
      Paren.new(lparen, e, rparen)
    end

    def group(lparen, e, rparen)
      Group.new(lparen, e, rparen)
    end

    def subsup(e, sub, sup)
      SubSup.new(e, sub, sup)
    end

    def sub(e, sub)
      SubSup.new(e, sub, nil)
    end

    def sup(e, sup)
      SubSup.new(e, nil, sup)
    end

    def unary(operator, e)
      UnaryOp.new(operator, e)
    end

    def binary(operator, e1, e2)
      BinaryOp.new(operator, e1, e2)
    end

    def infix(e1, operator, e2)
      InfixOp.new(operator, e1, e2)
    end

    def text(value)
      Text.new(value)
    end

    def number(value)
      Number.new(value)
    end

    def symbol(symbol, text)
      Symbol.new(symbol, text)
    end

    def identifier(value)
      Identifier.new(value)
    end

    def matrix(lparen, rows, rparen)
      Matrix.new(lparen, rows, rparen)
    end

    def color(r, g, b, text)
      Color.new(r, g, b, text)
    end

    class Node
      attr_reader :parent

      def initialize
        @parent = nil
      end

      protected

      attr_writer :parent
    end

    class InnerNode < Node
      include Enumerable

      def initialize
        super
        @children = []
      end

      def [](*args)
        @children[*args]
      end

      def length
        @children.length
      end

      def each(&block)
        @children.each(&block)
      end

      protected

      def child_nodes
        @children
      end
      
      def add(node)
        node.parent.remove(node) if node.parent
        node.parent = self
        child_nodes << node
      end

      def remove(node)
        node.parent = nil
        child_nodes.delete(node)
      end
    end

    class Sequence < InnerNode
      def initialize(nodes)
        super()
        nodes.each { |node| add(node) }
      end

      def to_s
        child_nodes.map { |node| node.to_s }.join(" ")
      end

      def ==(o)
        o.class == self.class && o.child_nodes == child_nodes
      end
    end

    class Paren < InnerNode
      attr_reader :lparen
      attr_reader :rparen

      def initialize(lparen, e, rparen)
        super()
        @lparen = lparen
        @rparen = rparen
        add(e) if e
      end

      def expression
        child_nodes[0]
      end

      def to_s
        "#{lparen.nil? ? '' : lparen.text}#{expression}#{rparen.nil? ? '' : rparen.text}"
      end

      def ==(o)
        o.class == self.class && o.lparen == lparen && o.expression == expression && o.rparen == rparen
      end
    end

    class Group < InnerNode
      attr_reader :lparen
      attr_reader :rparen

      def initialize(lparen, e, rparen)
        super()
        @lparen = lparen
        @rparen = rparen
        add(e) if e
      end

      def expression
        child_nodes[0]
      end

      def to_s
        "#{lparen.nil? ? '' : lparen.text}#{expression}#{rparen.nil? ? '' : rparen.text}"
      end

      def ==(o)
        o.class == self.class && o.lparen == lparen && o.expression == expression && o.rparen == rparen
      end
    end

    class SubSup < InnerNode
      def initialize(e, sub, sup)
        super()
        add(e)
        add(sub || Empty.new)
        add(sup || Empty.new)
      end

      def base_expression
        child_nodes[0]
      end

      def sub_expression
        child = child_nodes[1]
        child.is_a?(Empty) ? nil : child
      end

      def sup_expression
        child = child_nodes[2]
        child.is_a?(Empty) ? nil : child
      end

      def to_s
        s = ""
        s << base_expression.to_s
        sub = sub_expression
        if sub
          s << "_" << sub.to_s
        end
        sup = sup_expression
        if sup
          s << "^" << sup.to_s
        end
        s
      end

      def ==(o)
        o.class == self.class && o.base_expression == base_expression && o.sub_expression == sub_expression && o.sup_expression == sup_expression
      end
    end

    class UnaryOp < InnerNode
      def initialize(operator, e)
        super()
        add(operator)
        add(e)
      end

      def operator
        child_nodes[0]
      end

      def operand
        child_nodes[1]
      end

      def to_s
        "#{operator} #{operand}"
      end

      def ==(o)
        o.class == self.class && o.operator == operator && o.operand == operand
      end
    end

    class BinaryOp < InnerNode
      def initialize(operator, e1, e2)
        super()
        add(operator)
        add(e1)
        add(e2)
      end


      def operator
        child_nodes[0]
      end

      def operand1
        child_nodes[1]
      end

      def operand2
        child_nodes[2]
      end

      def to_s
        "#{operator} #{operand1} #{operand2}"
      end

      def ==(o)
        o.class == self.class && o.operator == operator && o.operand1 == operand1 && o.operand2 == operand2
      end
    end

    class InfixOp < InnerNode
      def initialize(operator, e1, e2)
        super()
        add(operator)
        add(e1)
        add(e2)
      end


      def operator
        child_nodes[0]
      end

      def operand1
        child_nodes[1]
      end

      def operand2
        child_nodes[2]
      end

      def to_s
        "#{operand1} #{operator} #{operand2}"
      end

      def ==(o)
        o.class == self.class && o.operator == operator && o.operand1 == operand1 && o.operand2 == operand2
      end
    end

    class ValueNode < Node
      attr_reader :value

      def initialize(value)
        super()
        @value = value
      end

      def to_s
        value.to_s
      end

      def ==(o)
        o.class == self.class && o.value == value
      end
    end

    class Text < ValueNode
      def initialize(value)
        super(value.dup.freeze)
      end

      def to_s
        '"' + super + '"'
      end
    end

    class Number < ValueNode
      def initialize(value)
        super(value.dup.freeze)
      end
    end

    class Symbol < ValueNode
      attr_reader :text

      def initialize(value, text)
        super(value)
        @text = text.dup.freeze
      end

      def ==(o)
        super && o.text == text
      end

      def to_s
        text
      end
    end

    class Identifier < ValueNode
      def initialize(value)
        super(value.dup.freeze)
      end
    end

    class Color < ValueNode
      attr_reader :text

      def initialize(r, g, b, text)
        super({:r => r, :g => g, :b => b}.freeze)
        @text = text.dup.freeze
      end

      def red
        value[:r]
      end

      def green
        value[:g]
      end

      def blue
        value[:b]
      end

      def ==(o)
        o.class == self.class &&
            o.red == red &&
            o.green == green &&
            o.blue == blue &&
            o.text == text
      end

      def to_hex_rgb
        sprintf('#%02x%02x%02x', red, green, blue)
      end

      def to_s
        text
      end
    end

    class Matrix < InnerNode
      attr_reader :lparen
      attr_reader :rparen

      def initialize(lparen, rows, rparen)
        super()
        @lparen = lparen
        @rparen = rparen
        rows.map { |row| MatrixRow.new(row) }.each { |row_seq| add(row_seq) }
      end

      def to_s
        s = ""
        s << (lparen.nil? ? '{:' : lparen.text)
        s << child_nodes.map { |node| node.to_s }.join(",")
        s << (rparen.nil? ? ':}' : rparen.text)
      end

      def ==(o)
        o.class == self.class &&
            o.lparen == lparen &&
            o.child_nodes == child_nodes &&
            o.rparen == rparen
      end
    end

    class MatrixRow < InnerNode
      def initialize(nodes)
        super()
        nodes.each { |node| add(node || Empty.new) }
      end

      def to_s
        "(" + child_nodes.map { |node| node.to_s }.join(",") + ")"
      end

      def ==(o)
        o.class == self.class && o.child_nodes == child_nodes
      end
    end

    class Empty < Node
      def initialize()
        super
      end

      def to_s
        ''
      end

      def ==(o)
        o.class == self.class
      end
    end
  end
end
