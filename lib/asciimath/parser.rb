require 'strscan'
require_relative 'ast'
require_relative 'color_table'
require_relative 'symbol_table'

# Parser for ASCIIMath expressions.
#
# The syntax for ASCIIMath in EBNF style notation is
#
# expr = ( simp ( fraction | sub | super ) )+
# simp = constant | paren_expr | unary_expr | binary_expr | text
# fraction = '/' simp
# super = '^' simp
# sub =  '_' simp super?
# paren_expr = lparen expr rparen
# lparen = '(' | '[' | '{' | '(:' | '{:'
# rparen = ')' | ']' | '}' | ':)' | ':}'
# unary_expr = unary_op simp
# unary_op = 'sqrt' | 'text'
# binary_expr = binary_op simp simp
# binary_op = 'frac' | 'root' | 'stackrel'
# text = '"' [^"]* '"'
# constant = number | symbol | identifier
# number = '-'? [0-9]+ ( '.' [0-9]+ )?
# symbol = /* any string in the symbol table */
# identifier = [A-z]
#
# ASCIIMath is parsed left to right without any form of operator precedence.
# When parsing the 'constant' the parser will try to find the longest matching string in the symbol
# table starting at the current position of the parser. If no matching string can be found the
# character at the current position of the parser is interpreted as an identifier instead.
module AsciiMath
  # Internal: Splits an ASCIIMath expression into a sequence of tokens.
  # Each token is represented as a Hash containing the keys :value and :type.
  # The :value key is used to store the text associated with each token.
  # The :type key indicates the semantics of the token. The value for :type will be one
  # of the following symbols:
  #
  # - :symbol a symbolic name or a bit of text without any further semantics
  # - :text a bit of arbitrary text
  # - :number a number
  # - :operator a mathematical operator symbol
  # - :unary a unary operator (e.g., sqrt, text, ...)
  # - :infix an infix operator (e.g, /, _, ^, ...)
  # - :binary a binary operator (e.g., frac, root, ...)
  # - :eof indicates no more tokens are available
  #
  class Tokenizer
    WHITESPACE = /\s+/
    NUMBER = /[0-9]+(?:\.[0-9]+)?/
    QUOTED_TEXT = /"[^"]*"/
    TEX_TEXT = /text\([^)]*\)/

    # Public: Initializes an ASCIIMath tokenizer.
    #
    # string - The ASCIIMath expression to tokenize
    # symbols - The symbol table to use while tokenizing
    def initialize(string, symbols)
      @string = StringScanner.new(string)
      @symbols = symbols
      lookahead = @symbols.keys.map { |k| k.length }.max
      @symbol_regexp = /((?:\\[\s0-9]|[^\s0-9]){1,#{lookahead}})/
      @push_back = nil
    end

    # Public: Read the next token from the ASCIIMath expression and move the tokenizer
    # ahead by one token.
    #
    # Returns the next token as a Hash
    def next_token
      if @push_back
        t = @push_back
        @push_back = nil
        return t
      end

      @string.scan(WHITESPACE)

      return {:value => nil, :type => :eof} if @string.eos?

      case @string.peek(1)
        when '"'
          read_quoted_text
        when 't'
          case @string.peek(5)
            when 'text('
              read_tex_text
            else
              read_symbol
          end
        when '-', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
          read_number || read_symbol
        else
          read_symbol
      end
    end

    # Public: Pushes the given token back to the tokenizer. A subsequent call to next_token
    # will return the given token rather than generating a new one. At most one
    # token can be pushed back.
    #
    # token - The token to push back
    def push_back(token)
      @push_back = token unless token[:type] == :eof
    end

    private

    # Private: Reads a text token from the input string
    #
    # Returns the text token or nil if a text token could not be matched at
    # the current position
    def read_quoted_text
      read_value(QUOTED_TEXT) do |text|
        {:value => text[1..-2], :type => :text}
      end
    end

    # Private: Reads a text token from the input string
    #
    # Returns the text token or nil if a text token could not be matched at
    # the current position
    def read_tex_text
      read_value(TEX_TEXT) do |text|
        {:value => text[5..-2], :type => :text}
      end
    end

    # Private: Reads a number token from the input string
    #
    # Returns the number token or nil if a number token could not be matched at
    # the current position
    def read_number
      read_value(NUMBER) do |number|
        {:value => number, :type => :number}
      end
    end

    if String.method_defined?(:bytesize)
      def bytesize(s)
        s.bytesize
      end
    else
      def bytesize(s)
        s.length
      end
    end


    # Private: Reads a symbol token from the input string. This method first creates
    # a String from the input String starting from the current position with a length
    # that matches that of the longest key in the symbol table. It then looks up that
    # substring in the symbol table. If the substring is present in the symbol table, the
    # associated value is returned and the position is moved ahead by the length of the
    # substring. Otherwise this method chops one character off the end of the substring
    # and repeats the symbol lookup. This continues until a single character is left.
    # If that character can still not be found in the symbol table, then an identifier
    # token is returned whose value is the remaining single character string.
    #
    # Returns the token that was read or nil if a token could not be matched at
    # the current position
    def read_symbol
      position = @string.pos
      read_value(@symbol_regexp) do |s|
        until s.length == 1 || @symbols.include?(s)
          s.chop!
        end
        @string.pos = position + bytesize(s)
        symbol = @symbols[s]
        if symbol
          symbol.merge({:text => s})
        else
          {:value => s, :type => :identifier}
        end
      end
    end

    # Private: Reads a String from the input String that matches the given RegExp
    #
    # regexp - a RegExp that will be used to match the token
    # block  - if a block is provided the matched token will be passed to the block
    #
    # Returns the matched String or the value returned by the block if one was given
    def read_value(regexp)
      s = @string.scan(regexp)
      if s && block_given?
        yield s
      else
        s
      end
    end

    if String.respond_to?(:byte_size)
      def byte_size(s)
        s.byte_size
      end
    end
  end

  class Parser
    def self.add_default_colors(b)
      b.add('aqua', 0, 255, 255)
      b.add('black', 0, 0, 0)
      b.add('blue', 0, 0, 255)
      b.add('fuchsia', 255, 0, 255)
      b.add('gray', 128, 128, 128)
      b.add('green', 0, 128, 0)
      b.add('lime', 0, 255, 0)
      b.add('maroon', 128, 0, 0)
      b.add('navy', 0, 0, 128)
      b.add('olive', 128, 128, 0)
      b.add('purple', 128, 0, 128)
      b.add('red', 255, 0, 0)
      b.add('silver', 192, 192, 192)
      b.add('teal', 0, 128, 128)
      b.add('white', 255, 255, 255)
      b.add('yellow', 255, 255, 0)
      b
    end

    def self.add_default_parser_symbols(b)
      # Operation symbols
      b.add('+', :plus, :symbol)
      b.add('-', :minus, :symbol)
      b.add('*', 'cdot', :cdot, :symbol)
      b.add('**', 'ast', :ast, :symbol)
      b.add('***', 'star', :star, :symbol)
      b.add('//', :slash, :symbol)
      b.add('\\\\', 'backslash', :backslash, :symbol)
      b.add('setminus', :setminus, :symbol)
      b.add('xx', 'times', :times, :symbol)
      b.add('|><', 'ltimes', :ltimes, :symbol)
      b.add('><|', 'rtimes', :rtimes, :symbol)
      b.add('|><|', 'bowtie', :bowtie, :symbol)
      b.add('-:', 'div', 'divide', :div, :symbol)
      b.add('@', 'circ', :circ, :symbol)
      b.add('o+', 'oplus', :oplus, :symbol)
      b.add('ox', 'otimes', :otimes, :symbol)
      b.add('o.', 'odot', :odot, :symbol)
      b.add('sum', :sum, :symbol)
      b.add('prod', :prod, :symbol)
      b.add('^^', 'wedge', :wedge, :symbol)
      b.add('^^^', 'bigwedge', :bigwedge, :symbol)
      b.add('vv', 'vee', :vee, :symbol)
      b.add('vvv', 'bigvee', :bigvee, :symbol)
      b.add('nn', 'cap', :cap, :symbol)
      b.add('nnn', 'bigcap', :bigcap, :symbol)
      b.add('uu', 'cup', :cup, :symbol)
      b.add('uuu', 'bigcup', :bigcup, :symbol)

      # Relation symbols
      b.add('=', :eq, :symbol)
      b.add('!=', 'ne', :ne, :symbol)
      b.add(':=', :assign, :symbol)
      b.add('<', 'lt', :lt, :symbol)
      b.add('>', 'gt', :gt, :symbol)
      b.add('<=', 'le', :le, :symbol)
      b.add('>=', 'ge', :ge, :symbol)
      b.add('-<', '-lt', 'prec', :prec, :symbol)
      b.add('>-', 'succ', :succ, :symbol)
      b.add('-<=', 'preceq', :preceq, :symbol)
      b.add('>-=', 'succeq', :succeq, :symbol)
      b.add('in', :in, :symbol)
      b.add('!in', 'notin', :notin, :symbol)
      b.add('sub', 'subset', :subset, :symbol)
      b.add('sup', 'supset', :supset, :symbol)
      b.add('sube', 'subseteq', :subseteq, :symbol)
      b.add('supe', 'supseteq', :supseteq, :symbol)
      b.add('-=', 'equiv', :equiv, :symbol)
      b.add('~=', 'cong', :cong, :symbol)
      b.add('~~', 'approx', :approx, :symbol)
      b.add('prop', 'propto', :propto, :symbol)

      # Logical symbols
      b.add('and', :and, :symbol)
      b.add('or', :or, :symbol)
      b.add('not', 'neg', :not, :symbol)
      b.add('=>', 'implies', :implies, :symbol)
      b.add('if', :if, :symbol)
      b.add('<=>', 'iff', :iff, :symbol)
      b.add('AA', 'forall', :forall, :symbol)
      b.add('EE', 'exists', :exists, :symbol)
      b.add('_|_', 'bot', :bot, :symbol)
      b.add('TT', 'top', :top, :symbol)
      b.add('|--', 'vdash', :vdash, :symbol)
      b.add('|==', 'models', :models, :symbol)

      # Grouping brackets
      b.add('(', 'left(', :lparen, :lparen)
      b.add(')', 'right)', :rparen, :rparen)
      b.add('[', 'left[', :lbracket, :lparen)
      b.add(']', 'right]', :rbracket, :rparen)
      b.add('{', :lbrace, :lparen)
      b.add('}', :rbrace, :rparen)
      b.add('|', :vbar, :lrparen)
      b.add(':|:', :vbar, :symbol)
      b.add('|:', :vbar, :lparen)
      b.add(':|', :vbar, :rparen)
      # b.add('||', '||', :lrparen)
      b.add('(:', '<<', 'langle', :langle, :lparen)
      b.add(':)', '>>', 'rangle', :rangle, :rparen)
      b.add('{:', nil, :lparen)
      b.add(':}', nil, :rparen)

      # Miscellaneous symbols
      b.add('int', :integral, :symbol)
      b.add('dx', :dx, :symbol)
      b.add('dy', :dy, :symbol)
      b.add('dz', :dz, :symbol)
      b.add('dt', :dt, :symbol)
      b.add('oint', :contourintegral, :symbol)
      b.add('del', 'partial', :partial, :symbol)
      b.add('grad', 'nabla', :nabla, :symbol)
      b.add('+-', 'pm', :pm, :symbol)
      b.add('O/', 'emptyset', :emptyset, :symbol)
      b.add('oo', 'infty', :infty, :symbol)
      b.add('aleph', :aleph, :symbol)
      b.add('...', 'ldots', :ellipsis, :symbol)
      b.add(':.', 'therefore', :therefore, :symbol)
      b.add(':\'', 'because', :because, :symbol)
      b.add('/_', 'angle', :angle, :symbol)
      b.add('/_\\', 'triangle', :triangle, :symbol)
      b.add('\'', 'prime', :prime, :symbol)
      b.add('tilde', :tilde, :unary)
      b.add('\\ ', :nbsp, :symbol)
      b.add('frown', :frown, :symbol)
      b.add('quad', :quad, :symbol)
      b.add('qquad', :qquad, :symbol)
      b.add('cdots', :cdots, :symbol)
      b.add('vdots', :vdots, :symbol)
      b.add('ddots', :ddots, :symbol)
      b.add('diamond', :diamond, :symbol)
      b.add('square', :square, :symbol)
      b.add('|__', 'lfloor', :lfloor, :symbol)
      b.add('__|', 'rfloor', :rfloor, :symbol)
      b.add('|~', 'lceiling', :lceiling, :symbol)
      b.add('~|', 'rceiling', :rceiling, :symbol)
      b.add('CC', :dstruck_captial_c, :symbol)
      b.add('NN', :dstruck_captial_n, :symbol)
      b.add('QQ', :dstruck_captial_q, :symbol)
      b.add('RR', :dstruck_captial_r, :symbol)
      b.add('ZZ', :dstruck_captial_z, :symbol)
      b.add('f', :f, :symbol)
      b.add('g', :g, :symbol)


      # Standard functions
      b.add('lim', :lim, :symbol)
      b.add('Lim', :Lim, :symbol)
      b.add('min', :min, :symbol)
      b.add('max', :max, :symbol)
      b.add('sin', :sin, :symbol)
      b.add('Sin', :Sin, :symbol)
      b.add('cos', :cos, :symbol)
      b.add('Cos', :Cos, :symbol)
      b.add('tan', :tan, :symbol)
      b.add('Tan', :Tan, :symbol)
      b.add('sinh', :sinh, :symbol)
      b.add('Sinh', :Sinh, :symbol)
      b.add('cosh', :cosh, :symbol)
      b.add('Cosh', :Cosh, :symbol)
      b.add('tanh', :tanh, :symbol)
      b.add('Tanh', :Tanh, :symbol)
      b.add('cot', :cot, :symbol)
      b.add('Cot', :Cot, :symbol)
      b.add('sec', :sec, :symbol)
      b.add('Sec', :Sec, :symbol)
      b.add('csc', :csc, :symbol)
      b.add('Csc', :Csc, :symbol)
      b.add('arcsin', :arcsin, :symbol)
      b.add('arccos', :arccos, :symbol)
      b.add('arctan', :arctan, :symbol)
      b.add('coth', :coth, :symbol)
      b.add('sech', :sech, :symbol)
      b.add('csch', :csch, :symbol)
      b.add('exp', :exp, :symbol)
      b.add('abs', :abs, :unary)
      b.add('Abs', :abs, :unary)
      b.add('norm', :norm, :unary)
      b.add('floor', :floor, :unary)
      b.add('ceil', :ceil, :unary)
      b.add('log', :log, :symbol)
      b.add('Log', :Log, :symbol)
      b.add('ln', :ln, :symbol)
      b.add('Ln', :Ln, :symbol)
      b.add('det', :det, :symbol)
      b.add('dim', :dim, :symbol)
      b.add('ker', :ker, :symbol)
      b.add('mod', :mod, :symbol)
      b.add('gcd', :gcd, :symbol)
      b.add('lcm', :lcm, :symbol)
      b.add('lub', :lub, :symbol)
      b.add('glb', :glb, :symbol)

      # Arrows
      b.add('uarr', 'uparrow', :uparrow, :symbol)
      b.add('darr', 'downarrow', :downarrow, :symbol)
      b.add('rarr', 'rightarrow', :rightarrow, :symbol)
      b.add('->', 'to', :to, :symbol)
      b.add('>->', 'rightarrowtail', :rightarrowtail, :symbol)
      b.add('->>', 'twoheadrightarrow', :twoheadrightarrow, :symbol)
      b.add('>->>', 'twoheadrightarrowtail', :twoheadrightarrowtail, :symbol)
      b.add('|->', 'mapsto', :mapsto, :symbol)
      b.add('larr', 'leftarrow', :leftarrow, :symbol)
      b.add('harr', 'leftrightarrow', :leftrightarrow, :symbol)
      b.add('rArr', 'Rightarrow', :Rightarrow, :symbol)
      b.add('lArr', 'Leftarrow', :Leftarrow, :symbol)
      b.add('hArr', 'Leftrightarrow', :Leftrightarrow, :symbol)

      # Other
      b.add('sqrt', :sqrt, :unary)
      b.add('root', :root, :binary)
      b.add('frac', :frac, :binary)
      b.add('/', :frac, :infix)
      b.add('stackrel', :stackrel, :binary)
      b.add('overset', :overset, :binary)
      b.add('underset', :underset, :binary)
      b.add('color', :color, :binary, :convert_operand1 => ::AsciiMath::Parser.instance_method(:convert_to_color))
      b.add('_', :sub, :infix)
      b.add('^', :sup, :infix)
      b.add('hat', :hat, :unary)
      b.add('bar', :overline, :unary)
      b.add('vec', :vec, :unary)
      b.add('dot', :dot, :unary)
      b.add('ddot', :ddot, :unary)
      b.add('overarc', 'overparen', :overarc, :unary)
      b.add('ul', 'underline', :underline, :unary)
      b.add('ubrace', 'underbrace', :underbrace, :unary)
      b.add('obrace', 'overbrace', :overbrace, :unary)
      b.add('cancel', :cancel, :unary)
      b.add('bb', :bold, :unary)
      b.add('bbb', :double_struck, :unary)
      b.add('ii', :italic, :unary)
      b.add('bii', :bold_italic, :unary)
      b.add('cc', :script, :unary)
      b.add('bcc', :bold_script, :unary)
      b.add('tt', :monospace, :unary)
      b.add('fr', :fraktur, :unary)
      b.add('bfr', :bold_fraktur, :unary)
      b.add('sf', :sans_serif, :unary)
      b.add('bsf', :bold_sans_serif, :unary)
      b.add('sfi', :sans_serif_italic, :unary)
      b.add('sfbi', :sans_serif_bold_italic, :unary)

      # Greek letters
      b.add('alpha', :alpha, :symbol)
      b.add('Alpha', :Alpha, :symbol)
      b.add('beta', :beta, :symbol)
      b.add('Beta', :Beta, :symbol)
      b.add('gamma', :gamma, :symbol)
      b.add('Gamma', :Gamma, :symbol)
      b.add('delta', :delta, :symbol)
      b.add('Delta', :Delta, :symbol)
      b.add('epsi', 'epsilon', :epsilon, :symbol)
      b.add('Epsilon', :Epsilon, :symbol)
      b.add('varepsilon', :varepsilon, :symbol)
      b.add('zeta', :zeta, :symbol)
      b.add('Zeta', :Zeta, :symbol)
      b.add('eta', :eta, :symbol)
      b.add('Eta', :Eta, :symbol)
      b.add('theta', :theta, :symbol)
      b.add('Theta', :Theta, :symbol)
      b.add('vartheta', :vartheta, :symbol)
      b.add('iota', :iota, :symbol)
      b.add('Iota', :Iota, :symbol)
      b.add('kappa', :kappa, :symbol)
      b.add('Kappa', :Kappa, :symbol)
      b.add('lambda', :lambda, :symbol)
      b.add('Lambda', :Lambda, :symbol)
      b.add('mu', :mu, :symbol)
      b.add('Mu', :Mu, :symbol)
      b.add('nu', :nu, :symbol)
      b.add('Nu', :Nu, :symbol)
      b.add('xi', :xi, :symbol)
      b.add('Xi', :Xi, :symbol)
      b.add('omicron', :omicron, :symbol)
      b.add('Omicron', :Omicron, :symbol)
      b.add('pi', :pi, :symbol)
      b.add('Pi', :Pi, :symbol)
      b.add('rho', :rho, :symbol)
      b.add('Rho', :Rho, :symbol)
      b.add('sigma', :sigma, :symbol)
      b.add('Sigma', :Sigma, :symbol)
      b.add('tau', :tau, :symbol)
      b.add('Tau', :Tau, :symbol)
      b.add('upsilon', :upsilon, :symbol)
      b.add('Upsilon', :Upsilon, :symbol)
      b.add('phi', :phi, :symbol)
      b.add('Phi', :Phi, :symbol)
      b.add('varphi', :varphi, :symbol)
      b.add('chi', :chi, :symbol)
      b.add('Chi', :Chi, :symbol)
      b.add('psi', :psi, :symbol)
      b.add('Psi', :Psi, :symbol)
      b.add('omega', :omega, :symbol)
      b.add('Omega', :Omega, :symbol)

      b
    end

    def initialize(symbol_table, color_table)
      @symbol_table = symbol_table
      @color_table = color_table
    end

    def parse(input)
      Expression.new(
          input,
          parse_expression(Tokenizer.new(input, @symbol_table), 0)
      )
    end

    private

    include AsciiMath::AST

    def parse_expression(tok, depth)
      e = []

      while (s1 = parse_intermediate_expression(tok, depth))
        t1 = tok.next_token

        if t1[:type] == :infix && t1[:value] == :frac
          s2 = parse_intermediate_expression(tok, depth)
          if s2
            e << infix(unwrap_paren(s1), symbol(:frac, t1[:text]), unwrap_paren(s2))
          else
            e << s1
          end
        elsif t1[:type] == :eof
          e << s1
          break
        else
          e << s1
          tok.push_back(t1)
          if (t1[:type] == :lrparen || t1[:type] == :rparen) && depth > 0
            break
          end
        end
      end

      expression(*e)
    end

    def parse_intermediate_expression(tok, depth)
      s = parse_simple_expression(tok, depth)
      sub = nil
      sup = nil

      t1 = tok.next_token
      case t1[:type]
        when :infix
          case t1[:value]
            when :sub
              sub = parse_simple_expression(tok, depth)
              if sub
                t2 = tok.next_token
                if t2[:type] == :infix && t2[:value] == :sup
                  sup = parse_simple_expression(tok, depth)
                else
                  tok.push_back(t2)
                end
              end
            when :sup
              sup = parse_simple_expression(tok, depth)
            else
              tok.push_back(t1)
          end
        else
          tok.push_back(t1)
      end

      if sub && sup
        subsup(s, unwrap_paren(sub), unwrap_paren(sup))
      elsif sub
        sub(s, unwrap_paren(sub))
      elsif sup
        sup(s, unwrap_paren(sup))
      else
        s
      end
    end

    def parse_simple_expression(tok, depth)
      t1 = tok.next_token

      case t1[:type]
        when :lparen, :lrparen
          t2 = tok.next_token
          case t2[:type]
            when :rparen, :lrparen
              paren(token_to_symbol(t1), nil, token_to_symbol(t2))
            else
              tok.push_back(t2)

              e = parse_expression(tok, depth + 1)

              t2 = tok.next_token
              case t2[:type]
                when :rparen, :lrparen
                  convert_to_matrix(paren(token_to_symbol(t1), e, token_to_symbol(t2)))
                else
                  tok.push_back(t2)
                  paren(token_to_symbol(t1), e, nil)
              end
          end
        when :rparen
          if depth > 0
            tok.push_back(t1)
            nil
          else
            token_to_symbol(t1)
          end
        when :unary
          s = unwrap_paren(parse_simple_expression(tok, depth))
          s = convert_node(s, t1[:convert_operand])
          unary(token_to_symbol(t1), s)
        when :binary
          s1 = unwrap_paren(parse_simple_expression(tok, depth))
          s2 = unwrap_paren(parse_simple_expression(tok, depth))

          s1 = convert_node(s1, t1[:convert_operand1])
          s2 = convert_node(s2, t1[:convert_operand2])

          binary(token_to_symbol(t1), s1, s2)
        when :eof
          nil
        when :number
          number(t1[:value])
        when :text
          text(t1[:value])
        when :identifier
          identifier(t1[:value])
        else
          token_to_symbol(t1)
      end
    end

    def token_to_symbol(t1)
      symbol(t1[:value], t1[:text])
    end

    def unwrap_paren(node)
      if node.is_a?(::AsciiMath::AST::Paren)
        group(node.lparen, node.expression, node.rparen)
      else
        node
      end
    end

    def convert_to_matrix(node)
      return node unless node.is_a?(::AsciiMath::AST::Paren) && node.expression.is_a?(::AsciiMath::AST::Sequence)

      rows, separators = node.expression.partition.with_index { |obj, i| i.even? }
      return node unless rows.length > 1 &&
          rows.length > separators.length &&
          separators.all? { |item| is_matrix_separator(item) } &&
          (rows.all? { |item| item.is_a?(::AsciiMath::AST::Paren) && item.lparen == symbol(:lparen, '(') && item.rparen == symbol(:rparen, ')') } ||
              rows.all? { |item| item.is_a?(::AsciiMath::AST::Paren) && item.lparen == symbol(:lbracket, '[') && item.rparen == symbol(:rbracket, ']') })

      rows = rows.map do |row|
        chunks = []
        current_chunk = []

        row_content = row.expression
        unless row_content.is_a?(::AsciiMath::AST::Sequence)
          [expression(row_content)]
        else
          row_content.each do |item|
            if is_matrix_separator(item)
              chunks << current_chunk
              current_chunk = []
            else
              current_chunk << item
            end
          end

          chunks << current_chunk

          chunks.map { |c| c.length == 1 ? c[0] : expression(*c) }.to_a
        end
      end

      return node unless rows.all? { |row| row.length == rows[0].length }

      matrix(node.lparen, rows, node.rparen)
    end

    def is_matrix_separator(node)
      node.is_a?(Identifier) && node.value == ','
    end

    def convert_node(node, converter)
      case converter
        when nil
          node
        when UnboundMethod
          converter.bind(self).call(node)
        when Method, Proc
          converter.call(node)
      end
    end

    def convert_to_color(color_expression)
      s = ""
      append_color_text(s, color_expression)
      s

      case s
        when /#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})/i
          color_value = {:r => $1.to_i(16), :g => $2.to_i(16), :b => $3.to_i(16), }
        when /#([0-9a-f])([0-9a-f])([0-9a-f])/i
          color_value = {:r => "#{$1}#{$1}".to_i(16), :g => "#{$2}#{$2}".to_i(16), :b => "#{$3}#{$3}".to_i(16), }
        else
          color_value = @color_table[s.downcase] || {:r => 0, :g => 0, :b => 0}
      end

      color(color_value[:r], color_value[:g], color_value[:b], s)
    end

    def append_color_text(s, node)
      case node
        when ::AsciiMath::AST::Sequence
          node.each { |n| append_color_text(s, n) }
        when ::AsciiMath::AST::Number, ::AsciiMath::AST::Identifier, ::AsciiMath::AST::Text
          s << node.value
        when ::AsciiMath::AST::Symbol
          s << node.text
        when ::AsciiMath::AST::Group
          append_color_text(s, node.expression)
        when ::AsciiMath::AST::Paren
          append_color_text(s, node.lparen)
          append_color_text(s, node.expression)
          append_color_text(s, node.rparen)
        when ::AsciiMath::AST::SubSup
          append_color_text(s, node.base_expression)
          append_color_text(s, node.operator)
          append_color_text(s, node.operand2)
        when ::AsciiMath::AST::UnaryOp
          append_color_text(s, node.operator)
          append_color_text(s, node.operand)
        when ::AsciiMath::AST::BinaryOp
          append_color_text(s, node.operator)
          append_color_text(s, node.operand1)
          append_color_text(s, node.operand2)
        when ::AsciiMath::AST::InfixOp
          append_color_text(s, node.operand1)
          append_color_text(s, node.operator)
          append_color_text(s, node.operand2)
      end
    end

    DEFAULT_COLOR_TABLE = ::AsciiMath::Parser.add_default_colors(AsciiMath::ColorTableBuilder.new).build
    DEFAULT_PARSER_SYMBOL_TABLE = ::AsciiMath::Parser.add_default_parser_symbols(AsciiMath::SymbolTableBuilder.new).build
  end

  class Expression
    attr_accessor :ast

    def initialize(asciimath, ast)
      @asciimath = asciimath
      @ast = ast
    end

    def to_s
      @asciimath
    end
  end

  def self.parse(asciimath, parser_symbol_table = ::AsciiMath::Parser::DEFAULT_PARSER_SYMBOL_TABLE, parser_color_table = ::AsciiMath::Parser::DEFAULT_COLOR_TABLE)
    Parser.new(parser_symbol_table, parser_color_table).parse(asciimath)
  end
end
