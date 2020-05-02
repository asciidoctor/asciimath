require 'strscan'
require_relative 'ast'

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
      @symbol_regexp = /([^\s0-9]{1,#{lookahead}})/
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
        @symbols[s] || {:value => s, :type => :symbol}
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
      if s
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

  module SymbolTable
    def self.create
      s = {}

      class << s
        def add(*names, value, type)
          entry = {:value => value, :type => type}.freeze
          names.each { |name| self[name.freeze] = entry }
        end
      end

      # Operation symbols
      s.add('+', :plus, :symbol)
      s.add('-', :minus, :symbol)
      s.add('*', 'cdot', :cdot, :symbol)
      s.add('**', 'ast', :ast, :symbol)
      s.add('***', 'star', :star, :symbol)
      s.add('//', :slash, :symbol)
      s.add('\\\\', 'backslash', :backslash, :symbol)
      s.add('setminus', :setminus, :symbol)
      s.add('xx', 'times', :times, :symbol)
      s.add('|><', 'ltimes', :ltimes, :symbol)
      s.add('><|', 'rtimes', :rtimes, :symbol)
      s.add('|><|', 'bowtie', :bowtie, :symbol)
      s.add('-:', 'div', 'divide', :div, :symbol)
      s.add('@', 'circ', :circ, :symbol)
      s.add('o+', 'oplus', :oplus, :symbol)
      s.add('ox', 'otimes', :otimes, :symbol)
      s.add('o.', 'odot', :odot, :symbol)
      s.add('sum', :sum, :symbol)
      s.add('prod', :prod, :symbol)
      s.add('^^', 'wedge', :wedge, :symbol)
      s.add('^^^', 'bigwedge', :bigwedge, :symbol)
      s.add('vv', 'vee', :vee, :symbol)
      s.add('vvv', 'bigvee', :bigvee, :symbol)
      s.add('nn', 'cap', :cap, :symbol)
      s.add('nnn', 'bigcap', :bigcap, :symbol)
      s.add('uu', 'cup', :cup, :symbol)
      s.add('uuu', 'bigcup', :bigcup, :symbol)

      # Relation symbols
      s.add('=', :eq, :symbol)
      s.add('!=', 'ne', :ne, :symbol)
      s.add(':=', :assign, :symbol)
      s.add('<', 'lt', :lt, :symbol)
      s.add('>', 'gt', :gt, :symbol)
      s.add('<=', 'le', :le, :symbol)
      s.add('>=', 'ge', :ge, :symbol)
      s.add('-<', '-lt', 'prec', :prec, :symbol)
      s.add('>-', 'succ', :succ, :symbol)
      s.add('-<=', 'preceq', :preceq, :symbol)
      s.add('>-=', 'succeq', :succeq, :symbol)
      s.add('in', :in, :symbol)
      s.add('!in', 'notin', :notin, :symbol)
      s.add('sub', 'subset', :subset, :symbol)
      s.add('sup', 'supset', :supset, :symbol)
      s.add('sube', 'subseteq', :subseteq, :symbol)
      s.add('supe', 'supseteq', :supseteq, :symbol)
      s.add('-=', 'equiv', :equiv, :symbol)
      s.add('~=', 'cong', :cong, :symbol)
      s.add('~~', 'approx', :approx, :symbol)
      s.add('prop', 'propto', :propto, :symbol)

      # Logical symbols
      s.add('and', :and, :symbol)
      s.add('or', :or, :symbol)
      s.add('not', 'neg', :not, :symbol)
      s.add('=>', 'implies', :implies, :symbol)
      s.add('if', :if, :symbol)
      s.add('<=>', 'iff', :iff, :symbol)
      s.add('AA', 'forall', :forall, :symbol)
      s.add('EE', 'exists', :exists, :symbol)
      s.add('_|_', 'bot', :bot, :symbol)
      s.add('TT', 'top', :top, :symbol)
      s.add('|--', 'vdash', :vdash, :symbol)
      s.add('|==', 'models', :models, :symbol)

      # Grouping brackets
      s.add('(', 'left(', :lparen, :lparen)
      s.add(')', 'right)', :rparen, :rparen)
      s.add('[', 'left[', :lbracket, :lparen)
      s.add(']', 'right]', :rbracket, :rparen)
      s.add('{', :lbrace, :lparen)
      s.add('}', :rbrace, :rparen)
      s.add('|', :vbar, :lrparen)
      s.add(':|:', :vbar, :symbol)
      s.add('|:', :vbar, :lparen)
      s.add(':|', :vbar, :rparen)
      # s.add('||', '||', :lrparen)
      s.add('(:', '<<', 'langle', :langle, :lparen)
      s.add(':)', '>>', 'rangle', :rangle, :rparen)
      s.add('{:', nil, :lparen)
      s.add(':}', nil, :rparen)

      # Miscellaneous symbols
      s.add('int', :integral, :symbol)
      s.add('dx', :dx, :symbol)
      s.add('dy', :dy, :symbol)
      s.add('dz', :dz, :symbol)
      s.add('dt', :dt, :symbol)
      s.add('oint', :contourintegral, :symbol)
      s.add('del', 'partial', :partial, :symbol)
      s.add('grad', 'nabla', :nabla, :symbol)
      s.add('+-', 'pm', :pm, :symbol)
      s.add('O/', 'emptyset', :emptyset, :symbol)
      s.add('oo', 'infty', :infty, :symbol)
      s.add('aleph', :aleph, :symbol)
      s.add('...', 'ldots', :ellipsis, :symbol)
      s.add(':.', 'therefore', :therefore, :symbol)
      s.add(':\'', 'because', :because, :symbol)
      s.add('/_', 'angle', :angle, :symbol)
      s.add('/_\\', 'triangle', :triangle, :symbol)
      s.add('\'', 'prime', :prime, :symbol)
      s.add('tilde', :tilde, :unary)
      s.add('\\ ', :nbsp, :symbol)
      s.add('frown', :frown, :symbol)
      s.add('quad', :quad, :symbol)
      s.add('qquad', :qquad, :symbol)
      s.add('cdots', :cdots, :symbol)
      s.add('vdots', :vdots, :symbol)
      s.add('ddots', :ddots, :symbol)
      s.add('diamond', :diamond, :symbol)
      s.add('square', :square, :symbol)
      s.add('|__', 'lfloor', :lfloor, :symbol)
      s.add('__|', 'rfloor', :rfloor, :symbol)
      s.add('|~', 'lceiling', :lceiling, :symbol)
      s.add('~|', 'rceiling', :rceiling, :symbol)
      s.add('CC', :dstruck_captial_c, :symbol)
      s.add('NN', :dstruck_captial_n, :symbol)
      s.add('QQ', :dstruck_captial_q, :symbol)
      s.add('RR', :dstruck_captial_r, :symbol)
      s.add('ZZ', :dstruck_captial_z, :symbol)
      s.add('f', :f, :symbol)
      s.add('g', :g, :symbol)


      # Standard functions
      s.add('lim', :lim, :symbol)
      s.add('Lim', :Lim, :symbol)
      s.add('min', :min, :symbol)
      s.add('max', :max, :symbol)
      s.add('sin', :sin, :symbol)
      s.add('Sin', :Sin, :symbol)
      s.add('cos', :cos, :symbol)
      s.add('Cos', :Cos, :symbol)
      s.add('tan', :tan, :symbol)
      s.add('Tan', :Tan, :symbol)
      s.add('sinh', :sinh, :symbol)
      s.add('Sinh', :Sinh, :symbol)
      s.add('cosh', :cosh, :symbol)
      s.add('Cosh', :Cosh, :symbol)
      s.add('tanh', :tanh, :symbol)
      s.add('Tanh', :Tanh, :symbol)
      s.add('cot', :cot, :symbol)
      s.add('Cot', :Cot, :symbol)
      s.add('sec', :sec, :symbol)
      s.add('Sec', :Sec, :symbol)
      s.add('csc', :csc, :symbol)
      s.add('Csc', :Csc, :symbol)
      s.add('arcsin', :arcsin, :symbol)
      s.add('arccos', :arccos, :symbol)
      s.add('arctan', :arctan, :symbol)
      s.add('coth', :coth, :symbol)
      s.add('sech', :sech, :symbol)
      s.add('csch', :csch, :symbol)
      s.add('exp', :exp, :symbol)
      s.add('abs', :abs, :unary)
      s.add('Abs', :abs, :unary)
      s.add('norm', :norm, :unary)
      s.add('floor', :floor, :unary)
      s.add('ceil', :ceil, :unary)
      s.add('log', :log, :symbol)
      s.add('Log', :Log, :symbol)
      s.add('ln', :ln, :symbol)
      s.add('Ln', :Ln, :symbol)
      s.add('det', :det, :symbol)
      s.add('dim', :dim, :symbol)
      s.add('mod', :mod, :symbol)
      s.add('gcd', :gcd, :symbol)
      s.add('lcm', :lcm, :symbol)
      s.add('lub', :lub, :symbol)
      s.add('glb', :glb, :symbol)

      # Arrows
      s.add('uarr', 'uparrow', :uparrow, :symbol)
      s.add('darr', 'downarrow', :downarrow, :symbol)
      s.add('rarr', 'rightarrow', :rightarrow, :symbol)
      s.add('->', 'to', :to, :symbol)
      s.add('>->', 'rightarrowtail', :rightarrowtail, :symbol)
      s.add('->>', 'twoheadrightarrow', :twoheadrightarrow, :symbol)
      s.add('>->>', 'twoheadrightarrowtail', :twoheadrightarrowtail, :symbol)
      s.add('|->', 'mapsto', :mapsto, :symbol)
      s.add('larr', 'leftarrow', :leftarrow, :symbol)
      s.add('harr', 'leftrightarrow', :leftrightarrow, :symbol)
      s.add('rArr', 'Rightarrow', :Rightarrow, :symbol)
      s.add('lArr', 'Leftarrow', :Leftarrow, :symbol)
      s.add('hArr', 'Leftrightarrow', :Leftrightarrow, :symbol)

      # Other
      s.add('sqrt', :sqrt, :unary)
      s.add('root', :root, :binary)
      s.add('frac', :frac, :binary)
      s.add('/', :frac, :infix)
      s.add('stackrel', :stackrel, :binary)
      s.add('overset', :overset, :binary)
      s.add('underset', :underset, :binary)
      s.add('_', :sub, :infix)
      s.add('^', :sup, :infix)
      s.add('hat', :hat, :unary)
      s.add('bar', :overline, :unary)
      s.add('vec', :vec, :unary)
      s.add('dot', :dot, :unary)
      s.add('ddot', :ddot, :unary)
      s.add('overarc', 'overparen', :overarc, :unary)
      s.add('ul', 'underline', :underline, :unary)
      s.add('ubrace', 'underbrace', :underbrace, :unary)
      s.add('obrace', 'overbrace', :overbrace, :unary)

      s.add('bb', :bold, :unary)
      s.add('bbb', :double_struck, :unary)
      s.add('ii', :italic, :unary)
      s.add('bii', :bold_italic, :unary)
      s.add('cc', :script, :unary)
      s.add('bcc', :bold_script, :unary)
      s.add('tt', :monospace, :unary)
      s.add('fr', :fraktur, :unary)
      s.add('bfr', :bold_fraktur, :unary)
      s.add('sf', :sans_serif, :unary)
      s.add('bsf', :bold_sans_serif, :unary)
      s.add('sfi', :sans_serif_italic, :unary)
      s.add('sfbi', :sans_serif_bold_italic, :unary)

      # Greek letters
      s.add('alpha', :alpha, :symbol)
      s.add('Alpha', :Alpha, :symbol)
      s.add('beta', :beta, :symbol)
      s.add('Beta', :Beta, :symbol)
      s.add('gamma', :gamma, :symbol)
      s.add('Gamma', :Gamma, :symbol)
      s.add('delta', :delta, :symbol)
      s.add('Delta', :Delta, :symbol)
      s.add('epsi', 'epsilon', :epsilon, :symbol)
      s.add('Epsilon', :Epsilon, :symbol)
      s.add('varepsilon', :varepsilon, :symbol)
      s.add('zeta', :zeta, :symbol)
      s.add('Zeta', :Zeta, :symbol)
      s.add('eta', :eta, :symbol)
      s.add('Eta', :Eta, :symbol)
      s.add('theta', :theta, :symbol)
      s.add('Theta', :Theta, :symbol)
      s.add('vartheta', :vartheta, :symbol)
      s.add('iota', :iota, :symbol)
      s.add('Iota', :Iota, :symbol)
      s.add('kappa', :kappa, :symbol)
      s.add('Kappa', :Kappa, :symbol)
      s.add('lambda', :lambda, :symbol)
      s.add('Lambda', :Lambda, :symbol)
      s.add('mu', :mu, :symbol)
      s.add('Mu', :Mu, :symbol)
      s.add('nu', :nu, :symbol)
      s.add('Nu', :Nu, :symbol)
      s.add('xi', :xi, :symbol)
      s.add('Xi', :Xi, :symbol)
      s.add('omicron', :omicron, :symbol)
      s.add('Omicron', :Omicron, :symbol)
      s.add('pi', :pi, :symbol)
      s.add('Pi', :Pi, :symbol)
      s.add('rho', :rho, :symbol)
      s.add('Rho', :Rho, :symbol)
      s.add('sigma', :sigma, :symbol)
      s.add('Sigma', :Sigma, :symbol)
      s.add('tau', :tau, :symbol)
      s.add('Tau', :Tau, :symbol)
      s.add('upsilon', :upsilon, :symbol)
      s.add('Upsilon', :Upsilon, :symbol)
      s.add('phi', :phi, :symbol)
      s.add('Phi', :Phi, :symbol)
      s.add('varphi', :varphi, :symbol)
      s.add('chi', :chi, :symbol)
      s.add('Chi', :Chi, :symbol)
      s.add('psi', :psi, :symbol)
      s.add('Psi', :Psi, :symbol)
      s.add('omega', :omega, :symbol)
      s.add('Omega', :Omega, :symbol)

      s.freeze
    end
  end

  class Parser
    include AsciiMath::AST

    SYMBOLS = AsciiMath::SymbolTable.create

    def parse(input)
      Expression.new(
          input,
          parse_expression(Tokenizer.new(input, SYMBOLS), 0)
      )
    end

    private

    def parse_expression(tok, depth)
      e = []

      while (s1 = parse_intermediate_expression(tok, depth))
        t1 = tok.next_token

        if t1[:type] == :infix && t1[:value] == :frac
          s2 = parse_intermediate_expression(tok, depth)
          if s2
            e << binary(:frac, unwrap_paren(s1), unwrap_paren(s2))
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

      if sub || sup
        subsup(s, unwrap_paren(sub), unwrap_paren(sup))
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
              paren(t1[:value], nil, t2[:value])
            else
              tok.push_back(t2)

              e = parse_expression(tok, depth + 1)

              t2 = tok.next_token
              case t2[:type]
                when :rparen, :lrparen
                  convert_to_matrix(paren(t1[:value], e, t2[:value]))
                else
                  tok.push_back(t2)
                  paren(t1[:value], e, nil)
              end
          end
        when :rparen
          if depth > 0
            tok.push_back(t1)
            nil
          else
            t1[:value]
          end
        when :unary
          s = unwrap_paren(parse_simple_expression(tok, depth))
          unary(t1[:value], s)
        when :binary
          s1 = unwrap_paren(parse_simple_expression(tok, depth))
          s2 = unwrap_paren(parse_simple_expression(tok, depth))
          binary(t1[:value], s1, s2)
        when :eof
          nil
        else
          t1[:value]
      end
    end

    def unwrap_paren(expression)
      if expression.is_a?(Hash) && expression[:type] == :paren
        expression[:e]
      else
        expression
      end
    end

    def convert_to_matrix(expression)
      return expression unless expression.is_a?(Hash) && expression[:type] == :paren && expression[:e].is_a?(Array)

      rows, separators = expression[:e].partition.with_index { |obj, i| i.even? }
      begin
        return expression unless rows.length > 1 &&
            rows.length > separators.length &&
            separators.all? { |item| is_matrix_separator(item) } &&
            (rows.all? { |item| item.is_a?(Hash) && item[:type] == :paren && item[:lparen] == :lparen && item[:rparen] == :rparen } ||
                rows.all? { |item| item.is_a?(Hash) && item[:type] == :paren && item[:lparen] == :lbracket && item[:rparen] == :rbracket })
      rescue
        raise e
      end

      rows = rows.map do |row|
        chunks = []
        current_chunk = []
        row[:e].each do |item|
          if is_matrix_separator(item)
            chunks << current_chunk
            current_chunk = []
          else
            current_chunk << item
          end
        end

        chunks << current_chunk

        chunks.map { |c| c.length == 1 ? c[0] : c }.to_a
      end

      return expression unless rows.all? { |row| row.length == rows[0].length }

      matrix(expression[:lparen], rows, expression[:rparen])
    end

    def is_matrix_separator(item)
      item == ','
    end

    def matrix?(expression)
      return false unless expression.is_a?(Hash) && expression[:type] == :paren

      rows, separators = expression[:e].partition.with_index { |obj, i| i.even? }

      rows.length > 1 &&
          rows.length > separators.length &&
          separators.all?(&method(:is_matrix_separator)) &&
          (rows.all? { |item| item[:type] == :paren && item[:lparen] == '(' && item[:rparen] == ')' } ||
              rows.all? { |item| item[:type] == :paren && item[:lparen] == '[' && item[:rparen] == ']' }) &&
          rows.all? { |item| item[:e].length == rows[0][:e].length } &&
          rows.all? { |item| matrix_cols?(item[:e]) }
    end

    def matrix_cols?(expression)
      return false unless expression.is_a?(Array)

      cols, separators = expression.partition.with_index { |obj, i| i.even? }

      cols.all? { |item| item[:type] != nil || item[:c] != ',' } &&
          separators.all?(&method(:is_col_separator))
    end
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

  def self.parse(asciimath)
    Parser.new.parse(asciimath)
  end
end
