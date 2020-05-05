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
      Sub.new(e, sub)
    end

    def sup(e, sup)
      Sup.new(e, sup)
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

      def children
        children.dup
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
        eq = o.class == self.class && o.child_nodes == child_nodes
        eq
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
        eq = o.class == self.class && o.lparen == lparen && o.expression == expression && o.rparen == rparen
        eq
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
        eq = o.class == self.class && o.lparen == lparen && o.expression == expression && o.rparen == rparen
        eq
      end
    end

    class SubSup < InnerNode
      def initialize(e, sub, sup)
        super()
        add(e)
        add(sub)
        add(sup)
      end

      def base_expression
        child_nodes[0]
      end

      def sub_expression
        child_nodes[1]
      end

      def sup_expression
        child_nodes[2]
      end

      def to_s
        "#{base_expression}_#{sub_expression}^#{sup_expression}"
      end

      def ==(o)
        eq = o.class == self.class && o.base_expression == base_expression && o.sub_expression == sub_expression && o.sup_expression == sup_expression
        eq
      end
    end

    class Sub < InnerNode
      def initialize(e, sub)
        super()
        add(e)
        add(sub)
      end

      def base_expression
        child_nodes[0]
      end

      def sub_expression
        child_nodes[1]
      end

      def to_s
        "#{base_expression}_#{sub_expression}"
      end

      def ==(o)
        eq = o.class == self.class && o.base_expression == base_expression && o.sub_expression == sub_expression
        eq
      end
    end

    class Sup < InnerNode
      def initialize(e, sup)
        super()
        add(e)
        add(sup)
      end

      def base_expression
        child_nodes[0]
      end

      def sup_expression
        child_nodes[1]
      end

      def to_s
        "#{base_expression}^#{sup_expression}"
      end

      def ==(o)
        eq = o.class == self.class && o.base_expression == base_expression && o.sup_expression == sup_expression
        eq
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
        eq = o.class == self.class && o.operator == operator && o.operand == operand
        eq
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
        eq = o.class == self.class && o.operator == operator && o.operand1 == operand1 && o.operand2 == operand2
        eq
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
        eq = o.class == self.class && o.operator == operator && o.operand1 == operand1 && o.operand2 == operand2
        eq
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
        eq = o.class == self.class && o.value == value
        eq
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
        eq = super && o.text == text
        eq
      end

      def to_s
        @text
      end
    end

    class Identifier < ValueNode
      def initialize(value)
        super(value.dup.freeze)
      end
    end

    class Matrix < InnerNode
      attr_reader :lparen
      attr_reader :rparen

      def initialize(lparen, rows, rparen)
        super()
        if lparen == :lbrace
          puts
        end

        @lparen = lparen
        @rparen = rparen
        rows.map { |row| MatrixRow.new(row) }.each { |row_seq| add(row_seq) }
      end

      alias_method :rows, :children

      def to_s
        begin
          s = ""
          s << (lparen.nil? ? '{:' : lparen.text)
          s << child_nodes.map { |node| node.to_s }.join(",")
          s << (rparen.nil? ? ':}' : rparen.text)
        rescue NoMethodError => e
          raise e
        end

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