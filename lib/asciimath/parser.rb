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

  class Parser
    include AsciiMath::AST

    SYMBOLS = {
        # Operation symbols
        '+' => {:value => :plus, :type => :symbol},
        '-' => {:value => :minus, :type => :symbol},
        '*' => {:value => :cdot, :type => :symbol},
        '**' => {:value => :ast, :type => :symbol},
        '***' => {:value => :star, :type => :symbol},
        '//' => {:value => :slash, :type => :symbol},
        '\\\\' => {:value => :backslash, :type => :symbol},
        'setminus' => {:value => :setminus, :type => :symbol},
        'xx' => {:value => :times, :type => :symbol},
        '|><' => {:value => :ltimes, :type => :symbol},
        '><|' => {:value => :rtimes, :type => :symbol},
        '|><|' => {:value => :bowtie, :type => :symbol},
        '-:' => {:value => :div, :type => :symbol},
        'divide' => {:value => :div, :type => :symbol},
        '@' => {:value => :circ, :type => :symbol},
        'o+' => {:value => :oplus, :type => :symbol},
        'ox' => {:value => :otimes, :type => :symbol},
        'o.' => {:value => :odot, :type => :symbol},
        'sum' => {:value => :sum, :type => :symbol},
        'prod' => {:value => :prod, :type => :symbol},
        '^^' => {:value => :wedge, :type => :symbol},
        '^^^' => {:value => :bigwedge, :type => :symbol},
        'vv' => {:value => :vee, :type => :symbol},
        'vvv' => {:value => :bigvee, :type => :symbol},
        'nn' => {:value => :cap, :type => :symbol},
        'nnn' => {:value => :bigcap, :type => :symbol},
        'uu' => {:value => :cup, :type => :symbol},
        'uuu' => {:value => :bigcup, :type => :symbol},

        # Relation symbols
        '=' => {:value => :eq, :type => :symbol},
        '!=' => {:value => :ne, :type => :symbol},
        ':=' => {:value => :assign, :type => :symbol},
        '<' => {:value => :lt, :type => :symbol},
        'lt' => {:value => :lt, :type => :symbol},
        '>' => {:value => :gt, :type => :symbol},
        'gt' => {:value => :gt, :type => :symbol},
        '<=' => {:value => :le, :type => :symbol},
        'le' => {:value => :le, :type => :symbol},
        '>=' => {:value => :ge, :type => :symbol},
        'ge' => {:value => :ge, :type => :symbol},
        '-<' => {:value => :prec, :type => :symbol},
        '-lt' => {:value => :prec, :type => :symbol},
        '>-' => {:value => :succ, :type => :symbol},
        '-<=' => {:value => :preceq, :type => :symbol},
        '>-=' => {:value => :succeq, :type => :symbol},
        'in' => {:value => :in, :type => :symbol},
        '!in' => {:value => :notin, :type => :symbol},
        'sub' => {:value => :subset, :type => :symbol},
        'sup' => {:value => :supset, :type => :symbol},
        'sube' => {:value => :subseteq, :type => :symbol},
        'supe' => {:value => :supseteq, :type => :symbol},
        '-=' => {:value => :equiv, :type => :symbol},
        '~=' => {:value => :cong, :type => :symbol},
        '~~' => {:value => :approx, :type => :symbol},
        'prop' => {:value => :propto, :type => :symbol},

        # Logical symbols
        'and' => {:value => :and, :type => :symbol},
        'or' => {:value => :or, :type => :symbol},
        'not' => {:value => :not, :type => :symbol},
        '=>' => {:value => :implies, :type => :symbol},
        'if' => {:value => :if, :type => :symbol},
        '<=>' => {:value => :iff, :type => :symbol},
        'AA' => {:value => :forall, :type => :symbol},
        'EE' => {:value => :exists, :type => :symbol},
        '_|_' => {:value => :bot, :type => :symbol},
        'TT' => {:value => :top, :type => :symbol},
        '|--' => {:value => :vdash, :type => :symbol},
        '|==' => {:value => :models, :type => :symbol},

        # Grouping brackets
        '(' => {:value => :lparen, :type => :lparen},
        ')' => {:value => :rparen, :type => :rparen},
        '[' => {:value => :lbracket, :type => :lparen},
        ']' => {:value => :rbracket, :type => :rparen},
        '{' => {:value => :lbrace, :type => :lparen},
        '}' => {:value => :rbrace, :type => :rparen},
        '|' => {:value => :vbar, :type => :lrparen},
        ':|:' => {:value => :vbar, :type => :symbol},
        '|:' => {:value => :vbar, :type => :lparen},
        ':|' => {:value => :vbar, :type => :rparen},
        # '||' => {:value => '||', :type => :lrparen},
        '(:' => {:value => :langle, :type => :lparen},
        ':)' => {:value => :rangle, :type => :rparen},
        '<<' => {:value => :langle, :type => :lparen},
        '>>' => {:value => :rangle, :type => :rparen},
        '{:' => {:value => nil, :type => :lparen},
        ':}' => {:value => nil, :type => :rparen},

        # Miscellaneous symbols
        'int' => {:value => :integral, :type => :symbol},
        'dx' => {:value => :dx, :type => :symbol},
        'dy' => {:value => :dy, :type => :symbol},
        'dz' => {:value => :dz, :type => :symbol},
        'dt' => {:value => :dt, :type => :symbol},
        'oint' => {:value => :contourintegral, :type => :symbol},
        'del' => {:value => :partial, :type => :symbol},
        'grad' => {:value => :nabla, :type => :symbol},
        '+-' => {:value => :pm, :type => :symbol},
        'O/' => {:value => :emptyset, :type => :symbol},
        'oo' => {:value => :infty, :type => :symbol},
        'aleph' => {:value => :aleph, :type => :symbol},
        '...' => {:value => :ellipsis, :type => :symbol},
        ':.' => {:value => :therefore, :type => :symbol},
        ':\'' => {:value => :because, :type => :symbol},
        '/_' => {:value => :angle, :type => :symbol},
        '/_\\' => {:value => :triangle, :type => :symbol},
        '\'' => {:value => :prime, :type => :symbol},
        'tilde' => {:value => :tilde, :type => :unary},
        '\\ ' => {:value => :nbsp, :type => :symbol},
        'frown' => {:value => :frown, :type => :symbol},
        'quad' => {:value => :quad, :type => :symbol},
        'qquad' => {:value => :qquad, :type => :symbol},
        'cdots' => {:value => :cdots, :type => :symbol},
        'vdots' => {:value => :vdots, :type => :symbol},
        'ddots' => {:value => :ddots, :type => :symbol},
        'diamond' => {:value => :diamond, :type => :symbol},
        'square' => {:value => :square, :type => :symbol},
        '|__' => {:value => :lfloor, :type => :symbol},
        '__|' => {:value => :rfloor, :type => :symbol},
        '|~' => {:value => :lceiling, :type => :symbol},
        '~|' => {:value => :rceiling, :type => :symbol},
        'CC' => {:value => :dstruck_captial_c, :type => :symbol},
        'NN' => {:value => :dstruck_captial_n, :type => :symbol},
        'QQ' => {:value => :dstruck_captial_q, :type => :symbol},
        'RR' => {:value => :dstruck_captial_r, :type => :symbol},
        'ZZ' => {:value => :dstruck_captial_z, :type => :symbol},
        'f' => {:value => :f, :type => :symbol},
        'g' => {:value => :g, :type => :symbol},


        # Standard functions
        'lim' => {:value => :lim, :type => :symbol},
        'Lim' => {:value => :Lim, :type => :symbol},
        'min' => {:value => :min, :type => :symbol},
        'max' => {:value => :max, :type => :symbol},
        'sin' => {:value => :sin, :type => :symbol},
        'Sin' => {:value => :Sin, :type => :symbol},
        'cos' => {:value => :cos, :type => :symbol},
        'Cos' => {:value => :Cos, :type => :symbol},
        'tan' => {:value => :tan, :type => :symbol},
        'Tan' => {:value => :Tan, :type => :symbol},
        'sinh' => {:value => :sinh, :type => :symbol},
        'Sinh' => {:value => :Sinh, :type => :symbol},
        'cosh' => {:value => :cosh, :type => :symbol},
        'Cosh' => {:value => :Cosh, :type => :symbol},
        'tanh' => {:value => :tanh, :type => :symbol},
        'Tanh' => {:value => :Tanh, :type => :symbol},
        'cot' => {:value => :cot, :type => :symbol},
        'Cot' => {:value => :Cot, :type => :symbol},
        'sec' => {:value => :sec, :type => :symbol},
        'Sec' => {:value => :Sec, :type => :symbol},
        'csc' => {:value => :csc, :type => :symbol},
        'Csc' => {:value => :Csc, :type => :symbol},
        'arcsin' => {:value => :arcsin, :type => :symbol},
        'arccos' => {:value => :arccos, :type => :symbol},
        'arctan' => {:value => :arctan, :type => :symbol},
        'coth' => {:value => :coth, :type => :symbol},
        'sech' => {:value => :sech, :type => :symbol},
        'csch' => {:value => :csch, :type => :symbol},
        'exp' => {:value => :exp, :type => :symbol},
        'abs' => {:value => :abs, :type => :unary},
        'Abs' => {:value => :abs, :type => :unary},
        'norm' => {:value => :norm, :type => :unary},
        'floor' => {:value => :floor, :type => :unary},
        'ceil' => {:value => :ceil, :type => :unary},
        'log' => {:value => :log, :type => :symbol},
        'Log' => {:value => :Log, :type => :symbol},
        'ln' => {:value => :ln, :type => :symbol},
        'Ln' => {:value => :Ln, :type => :symbol},
        'det' => {:value => :det, :type => :symbol},
        'dim' => {:value => :dim, :type => :symbol},
        'mod' => {:value => :mod, :type => :symbol},
        'gcd' => {:value => :gcd, :type => :symbol},
        'lcm' => {:value => :lcm, :type => :symbol},
        'lub' => {:value => :lub, :type => :symbol},
        'glb' => {:value => :glb, :type => :symbol},

        # Arrows
        'uarr' => {:value => :uparrow, :type => :symbol},
        'darr' => {:value => :downarrow, :type => :symbol},
        'rarr' => {:value => :rightarrow, :type => :symbol},
        '->' => {:value => :to, :type => :symbol},
        '>->' => {:value => :rightarrowtail, :type => :symbol},
        '->>' => {:value => :twoheadrightarrow, :type => :symbol},
        '>->>' => {:value => :twoheadrightarrowtail, :type => :symbol},
        '|->' => {:value => :mapsto, :type => :symbol},
        'larr' => {:value => :leftarrow, :type => :symbol},
        'harr' => {:value => :leftrightarrow, :type => :symbol},
        'rArr' => {:value => :Rightarrow, :type => :symbol},
        'lArr' => {:value => :Leftarrow, :type => :symbol},
        'hArr' => {:value => :Leftrightarrow, :type => :symbol},

        # Other
        'sqrt' => {:value => :sqrt, :type => :unary},
        'root' => {:value => :root, :type => :binary},
        'frac' => {:value => :frac, :type => :binary},
        '/' => {:value => :frac, :type => :infix},
        'stackrel' => {:value => :stackrel, :type => :binary},
        'overset' => {:value => :overset, :type => :binary},
        'underset' => {:value => :underset, :type => :binary},
        '_' => {:value => :sub, :type => :infix},
        '^' => {:value => :sup, :type => :infix},
        'hat' => {:value => :hat, :type => :unary},
        'bar' => {:value => :overline, :type => :unary},
        'vec' => {:value => :vec, :type => :unary},
        'dot' => {:value => :dot, :type => :unary},
        'ddot' => {:value => :ddot, :type => :unary},
        'overarc' => {:value => :overarc, :type => :unary},
        'ul' => {:value => :underline, :type => :unary},
        'ubrace' => {:value => :underbrace, :type => :unary},
        'obrace' => {:value => :overbrace, :type => :unary},

        'bb' => {:value => :bold, :type => :unary},
        'bbb' => {:value => :double_struck, :type => :unary},
        'ii' => {:value => :italic, :type => :unary},
        'bii' => {:value => :bold_italic, :type => :unary},
        'cc' => {:value => :script, :type => :unary},
        'bcc' => {:value => :bold_script, :type => :unary},
        'tt' => {:value => :monospace, :type => :unary},
        'fr' => {:value => :fraktur, :type => :unary},
        'bfr' => {:value => :bold_fraktur, :type => :unary},
        'sf' => {:value => :sans_serif, :type => :unary},
        'bsf' => {:value => :bold_sans_serif, :type => :unary},
        'sfi' => {:value => :sans_serif_italic, :type => :unary},
        'sfbi' => {:value => :sans_serif_bold_italic, :type => :unary},

        # Greek letters
        'alpha' => {:value => :alpha, :type => :symbol},
        'Alpha' => {:value => :Alpha, :type => :symbol},
        'beta' => {:value => :beta, :type => :symbol},
        'Beta' => {:value => :Beta, :type => :symbol},
        'gamma' => {:value => :gamma, :type => :symbol},
        'Gamma' => {:value => :Gamma, :type => :symbol},
        'delta' => {:value => :delta, :type => :symbol},
        'Delta' => {:value => :Delta, :type => :symbol},
        'epsilon' => {:value => :epsilon, :type => :symbol},
        'Epsilon' => {:value => :Epsilon, :type => :symbol},
        'varepsilon' => {:value => :varepsilon, :type => :symbol},
        'zeta' => {:value => :zeta, :type => :symbol},
        'Zeta' => {:value => :Zeta, :type => :symbol},
        'eta' => {:value => :eta, :type => :symbol},
        'Eta' => {:value => :Eta, :type => :symbol},
        'theta' => {:value => :theta, :type => :symbol},
        'Theta' => {:value => :Theta, :type => :symbol},
        'vartheta' => {:value => :vartheta, :type => :symbol},
        'iota' => {:value => :iota, :type => :symbol},
        'Iota' => {:value => :Iota, :type => :symbol},
        'kappa' => {:value => :kappa, :type => :symbol},
        'Kappa' => {:value => :Kappa, :type => :symbol},
        'lambda' => {:value => :lambda, :type => :symbol},
        'Lambda' => {:value => :Lambda, :type => :symbol},
        'mu' => {:value => :mu, :type => :symbol},
        'Mu' => {:value => :Mu, :type => :symbol},
        'nu' => {:value => :nu, :type => :symbol},
        'Nu' => {:value => :Nu, :type => :symbol},
        'xi' => {:value => :xi, :type => :symbol},
        'Xi' => {:value => :Xi, :type => :symbol},
        'omicron' => {:value => :omicron, :type => :symbol},
        'Omicron' => {:value => :Omicron, :type => :symbol},
        'pi' => {:value => :pi, :type => :symbol},
        'Pi' => {:value => :Pi, :type => :symbol},
        'rho' => {:value => :rho, :type => :symbol},
        'Rho' => {:value => :Rho, :type => :symbol},
        'sigma' => {:value => :sigma, :type => :symbol},
        'Sigma' => {:value => :Sigma, :type => :symbol},
        'tau' => {:value => :tau, :type => :symbol},
        'Tau' => {:value => :Tau, :type => :symbol},
        'upsilon' => {:value => :upsilon, :type => :symbol},
        'Upsilon' => {:value => :Upsilon, :type => :symbol},
        'phi' => {:value => :phi, :type => :symbol},
        'Phi' => {:value => :Phi, :type => :symbol},
        'varphi' => {:value => :varphi, :type => :symbol},
        'chi' => {:value => :chi, :type => :symbol},
        'Chi' => {:value => :Chi, :type => :symbol},
        'psi' => {:value => :psi, :type => :symbol},
        'Psi' => {:value => :Psi, :type => :symbol},
        'omega' => {:value => :omega, :type => :symbol},
        'Omega' => {:value => :Omega, :type => :symbol},
    }

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
