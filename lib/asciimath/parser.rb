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
  # - :font a unary font command (e.g., bb, cc, ...)
  # - :infix an infix operator (e.g, /, _, ^, ...)
  # - :binary a binary operator (e.g., frac, root, ...)
  # - :accent an accent character
  # - :eof indicates no more tokens are available
  #
  # Each token type may also have an :underover modifier. When present and set to true
  # sub- and superscript expressions associated with the token will be rendered as
  # under- and overscriptabove and below rather than as sub- or superscript.
  #
  # :accent tokens additionally have a :postion value which is set to either :over or :under.
  # This determines if the accent should be rendered over or under the expression to which
  # it applies.
  #
  class Tokenizer
    WHITESPACE = /\s+/
    NUMBER = /-?[0-9]+(?:\.[0-9]+)?/
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
        @symbols[s] || {:value => s, :type => nil}
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
        '+' => {:value => :plus, :type => nil},
        '-' => {:value => :minus, :type => nil},
        '*' => {:value => :cdot, :type => nil},
        '**' => {:value => :ast, :type => nil},
        '***' => {:value => :star, :type => nil},
        '//' => {:value => :slash, :type => nil},
        '\\\\' => {:value => :backslash, :type => nil},
        'setminus' => {:value => :setminus, :type => nil},
        'xx' => {:value => :times, :type => nil},
        '|><' => {:value => :ltimes, :type => nil},
        '><|' => {:value => :rtimes, :type => nil},
        '|><|' => {:value => :bowtie, :type => nil},
        '-:' => {:value => :div, :type => nil},
        'divide' => {:value => :div, :type => nil},
        '@' => {:value => :circ, :type => nil},
        'o+' => {:value => :oplus, :type => nil},
        'ox' => {:value => :otimes, :type => nil},
        'o.' => {:value => :odot, :type => nil},
        'sum' => {:value => :sum, :type => nil},
        'prod' => {:value => :prod, :type => nil},
        '^^' => {:value => :wedge, :type => nil},
        '^^^' => {:value => :bidwedge, :type => nil},
        'vv' => {:value => :vee, :type => nil},
        'vvv' => {:value => :bigvee, :type => nil},
        'nn' => {:value => :cap, :type => nil},
        'nnn' => {:value => :bigcap, :type => nil},
        'uu' => {:value => :cup, :type => nil},
        'uuu' => {:value => :bigcup, :type => nil},

        # Relation symbols
        '=' => {:value => :eq, :type => nil},
        '!=' => {:value => :ne, :type => nil},
        ':=' => {:value => :assign, :type => nil},
        '<' => {:value => :lt, :type => nil},
        'lt' => {:value => :lt, :type => nil},
        '>' => {:value => :gt, :type => nil},
        'gt' => {:value => :gt, :type => nil},
        '<=' => {:value => :le, :type => nil},
        'le' => {:value => :le, :type => nil},
        '>=' => {:value => :ge, :type => nil},
        'ge' => {:value => :ge, :type => nil},
        '-<' => {:value => :prec, :type => nil},
        '-lt' => {:value => :prec, :type => nil},
        '>-' => {:value => :succ, :type => nil},
        '-<=' => {:value => :preceq, :type => nil},
        '>-=' => {:value => :succeq, :type => nil},
        'in' => {:value => :in, :type => nil},
        '!in' => {:value => :notin, :type => nil},
        'sub' => {:value => :subset, :type => nil},
        'sup' => {:value => :supset, :type => nil},
        'sube' => {:value => :subseteq, :type => nil},
        'supe' => {:value => :supseteq, :type => nil},
        '-=' => {:value => :equiv, :type => nil},
        '~=' => {:value => :cong, :type => nil},
        '~~' => {:value => :approx, :type => nil},
        'prop' => {:value => :propto, :type => nil},

        # Logical symbols
        'and' => {:value => :and, :type => :identifier},
        'or' => {:value => :or, :type => :identifier},
        'not' => {:value => :not, :type => nil},
        '=>' => {:value => :implies, :type => nil},
        'if' => {:value => :if, :type => nil},
        '<=>' => {:value => :iff, :type => nil},
        'AA' => {:value => :forall, :type => nil},
        'EE' => {:value => :exists, :type => nil},
        '_|_' => {:value => :bot, :type => nil},
        'TT' => {:value => :top, :type => nil},
        '|--' => {:value => :vdash, :type => nil},
        '|==' => {:value => :models, :type => nil},

        # Grouping brackets
        '(' => {:value => :lparen, :type => :lparen},
        ')' => {:value => :rparen, :type => :rparen},
        '[' => {:value => :lbracket, :type => :lparen},
        ']' => {:value => :rbracket, :type => :rparen},
        '{' => {:value => :lbrace, :type => :lparen},
        '}' => {:value => :rbrace, :type => :rparen},
        '|' => {:value => :vbar, :type => :lrparen},
        ':|:' => {:value => :vbar, :type => nil},
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
        'int' => {:value => :integral, :type => nil},
        'dx' => {:value => :dx, :type => nil},
        'dy' => {:value => :dy, :type => nil},
        'dz' => {:value => :dz, :type => nil},
        'dt' => {:value => :dt, :type => nil},
        'oint' => {:value => :contourintegral, :type => nil},
        'del' => {:value => :partial, :type => nil},
        'grad' => {:value => :nabla, :type => nil},
        '+-' => {:value => :pm, :type => nil},
        'O/' => {:value => :emptyset, :type => nil},
        'oo' => {:value => :infty, :type => nil},
        'aleph' => {:value => :aleph, :type => nil},
        '...' => {:value => '...', :type => nil},
        ':.' => {:value => :therefore, :type => nil},
        ':\'' => {:value => :because, :type => nil},
        '/_' => {:value => :angle, :type => nil},
        '/_\\' => {:value => :triangle, :type => nil},
        '\'' => {:value => :prime, :type => nil},
        'tilde' => {:value => :tilde, :type => :accent},
        '\\ ' => {:value => :nbsp, :type => nil},
        'frown' => {:value => :frown, :type => nil},
        'quad' => {:value => :quad, :type => nil},
        'qquad' => {:value => :qquad, :type => nil},
        'cdots' => {:value => :cdots, :type => nil},
        'vdots' => {:value => :vdots, :type => nil},
        'ddots' => {:value => :ddots, :type => nil},
        'diamond' => {:value => :diamond, :type => nil},
        'square' => {:value => :square, :type => nil},
        '|__' => {:value => :lfloor, :type => nil},
        '__|' => {:value => :rfloor, :type => nil},
        '|~' => {:value => :lceiling, :type => nil},
        '~|' => {:value => :rceiling, :type => nil},
        'CC' => {:value => :dstruck_captial_c, :type => nil},
        'NN' => {:value => :dstruck_captial_n, :type => nil},
        'QQ' => {:value => :dstruck_captial_q, :type => nil},
        'RR' => {:value => :dstruck_captial_r, :type => nil},
        'ZZ' => {:value => :dstruck_captial_z, :type => nil},
        'f' => {:value => :f, :type => nil},
        'g' => {:value => :g, :type => nil},


        # Standard functions
        'lim' => {:value => :lim, :type => nil},
        'Lim' => {:value => :Lim, :type => nil},
        'min' => {:value => :min, :type => nil},
        'max' => {:value => :max, :type => nil},
        'sin' => {:value => :sin, :type => :func},
        'Sin' => {:value => :Sin, :type => :func},
        'cos' => {:value => :cos, :type => :func},
        'Cos' => {:value => :Cos, :type => :func},
        'tan' => {:value => :tan, :type => :func},
        'Tan' => {:value => :Tan, :type => :func},
        'sinh' => {:value => :sinh, :type => :func},
        'Sinh' => {:value => :Sinh, :type => :func},
        'cosh' => {:value => :cosh, :type => :func},
        'Cosh' => {:value => :Cosh, :type => :func},
        'tanh' => {:value => :tanh, :type => :func},
        'Tanh' => {:value => :Tanh, :type => :func},
        'cot' => {:value => :cot, :type => :func},
        'Cot' => {:value => :Cot, :type => :func},
        'sec' => {:value => :sec, :type => :func},
        'Sec' => {:value => :Sec, :type => :func},
        'csc' => {:value => :csc, :type => :func},
        'Csc' => {:value => :Csc, :type => :func},
        'arcsin' => {:value => :arcsin, :type => :func},
        'arccos' => {:value => :arccos, :type => :func},
        'arctan' => {:value => :arctan, :type => :func},
        'coth' => {:value => :coth, :type => :func},
        'sech' => {:value => :sech, :type => :func},
        'csch' => {:value => :csch, :type => :func},
        'exp' => {:value => :exp, :type => :func},
        'abs' => {:value => :abs, :type => :func, :wrap_left => :vbar, :wrap_right => :vbar},
        'Abs' => {:value => :Abs, :type => :func, :wrap_left => :vbar, :wrap_right => :vbar},
        'norm' => {:value => :norm, :type => :func, :wrap_left => :parallel, :wrap_right => :parallel},
        'floor' => {:value => :floor, :type => :func, :wrap_left => :lfloor, :wrap_right => :rfloor},
        'ceil' => {:value => :ceil, :type => :func, :wrap_left => :lceiling, :wrap_right => :rceiling},
        'log' => {:value => :log, :type => :func},
        'Log' => {:value => :Log, :type => :func},
        'ln' => {:value => :ln, :type => :func},
        'Ln' => {:value => :Ln, :type => :func},
        'det' => {:value => :det, :type => :func},
        'dim' => {:value => :dim, :type => :func},
        'mod' => {:value => :mod, :type => :func},
        'gcd' => {:value => :gcd, :type => :func},
        'lcm' => {:value => :lcm, :type => :func},
        'lub' => {:value => :lub, :type => :func},
        'glb' => {:value => :glb, :type => :func},

        # Arrows
        'uarr' => {:value => :uparrow, :type => nil},
        'darr' => {:value => :downarrow, :type => nil},
        'rarr' => {:value => :rightarrow, :type => nil},
        '->' => {:value => :to, :type => nil},
        '>->' => {:value => :rightarrowtail, :type => nil},
        '->>' => {:value => :twoheadrightarrow, :type => nil},
        '>->>' => {:value => :twoheadrightarrowtail, :type => nil},
        '|->' => {:value => :mapsto, :type => nil},
        'larr' => {:value => :leftarrow, :type => nil},
        'harr' => {:value => :leftrightarrow, :type => nil},
        'rArr' => {:value => :Rightarrow, :type => nil},
        'lArr' => {:value => :Leftarrow, :type => nil},
        'hArr' => {:value => :Leftrightarrow, :type => nil},

        # Other
        'sqrt' => {:value => :sqrt, :type => :unary},
        'root' => {:value => :root, :type => :binary},
        'frac' => {:value => :frac, :type => :binary},
        '/' => {:value => :frac, :type => :infix},
        'stackrel' => {:value => :stackrel, :type => :binary, :switch_operands => true},
        'overset' => {:value => :overset, :type => :binary, :switch_operands => true},
        'underset' => {:value => :underset, :type => :binary, :switch_operands => true},
        '_' => {:value => :sub, :type => :infix},
        '^' => {:value => :sup, :type => :infix},
        'hat' => {:value => :hat, :type => :accent, :position => :over},
        'bar' => {:value => :overline, :type => :accent, :position => :over},
        'vec' => {:value => :vec, :type => :accent, :position => :over},
        'dot' => {:value => :dot, :type => :accent, :position => :over},
        'ddot' => {:value => :ddot, :type => :accent, :position => :over},
        'overarc' => {:value => :overarc, :type => :accent, :position => :over},
        'ul' => {:value => :underline, :type => :accent, :position => :under},
        'ubrace' => {:value => :underbrace, :type => :accent, :position => :under},
        'obrace' => {:value => :overbrace, :type => :accent, :position => :over},

        'bb' => {:value => :bold, :type => :font},
        'bbb' => {:value => :double_struck, :type => :font},
        'ii' => {:value => :italic, :type => :font},
        'bii' => {:value => :bold_italic, :type => :font},
        'cc' => {:value => :script, :type => :font},
        'bcc' => {:value => :bold_script, :type => :font},
        'tt' => {:value => :monospace, :type => :font},
        'fr' => {:value => :fraktur, :type => :font},
        'bfr' => {:value => :bold_fraktur, :type => :font},
        'sf' => {:value => :sans_serif, :type => :font},
        'bsf' => {:value => :bold_sans_serif, :type => :font},
        'sfi' => {:value => :sans_serif_italic, :type => :font},
        'sfbi' => {:value => :sans_serif_bold_italic, :type => :font},

        # Greek letters
        'alpha' => {:value => :alpha, :type => nil},
        'Alpha' => {:value => :Alpha, :type => nil},
        'beta' => {:value => :beta, :type => nil},
        'Beta' => {:value => :Beta, :type => nil},
        'gamma' => {:value => :gamma, :type => nil},
        'Gamma' => {:value => :Gamma, :type => nil},
        'delta' => {:value => :delta, :type => nil},
        'Delta' => {:value => :Delta, :type => nil},
        'epsilon' => {:value => :epsilon, :type => nil},
        'Epsilon' => {:value => :Epsilon, :type => nil},
        'varepsilon' => {:value => :varepsilon, :type => nil},
        'zeta' => {:value => :zeta, :type => nil},
        'Zeta' => {:value => :Zeta, :type => nil},
        'eta' => {:value => :eta, :type => nil},
        'Eta' => {:value => :Eta, :type => nil},
        'theta' => {:value => :theta, :type => nil},
        'Theta' => {:value => :Theta, :type => nil},
        'vartheta' => {:value => :vartheta, :type => nil},
        'iota' => {:value => :iota, :type => nil},
        'Iota' => {:value => :Iota, :type => nil},
        'kappa' => {:value => :kappa, :type => nil},
        'Kappa' => {:value => :Kappa, :type => nil},
        'lambda' => {:value => :lambda, :type => nil},
        'Lambda' => {:value => :Lambda, :type => nil},
        'mu' => {:value => :mu, :type => nil},
        'Mu' => {:value => :Mu, :type => nil},
        'nu' => {:value => :nu, :type => nil},
        'Nu' => {:value => :Nu, :type => nil},
        'xi' => {:value => :xi, :type => nil},
        'Xi' => {:value => :Xi, :type => nil},
        'omicron' => {:value => :omicron, :type => nil},
        'Omicron' => {:value => :Omicron, :type => nil},
        'pi' => {:value => :pi, :type => nil},
        'Pi' => {:value => :Pi, :type => nil},
        'rho' => {:value => :rho, :type => nil},
        'Rho' => {:value => :Rho, :type => nil},
        'sigma' => {:value => :sigma, :type => nil},
        'Sigma' => {:value => :Sigma, :type => nil},
        'tau' => {:value => :tau, :type => nil},
        'Tau' => {:value => :Tau, :type => nil},
        'upsilon' => {:value => :upsilon, :type => nil},
        'Upsilon' => {:value => :Upsilon, :type => nil},
        'phi' => {:value => :phi, :type => nil},
        'Phi' => {:value => :Phi, :type => nil},
        'varphi' => {:value => :varphi, :type => nil},
        'chi' => {:value => :chi, :type => nil},
        'Chi' => {:value => :Chi, :type => nil},
        'psi' => {:value => :psi, :type => nil},
        'Psi' => {:value => :Psi, :type => nil},
        'omega' => {:value => :omega, :type => nil},
        'Omega' => {:value => :Omega, :type => nil},
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
              paren(t1[:value], e, t2[:value])
            else
              tok.push_back(t2)

              e = parse_expression(tok, depth + 1)

              t2 = tok.next_token
              case t2[:type]
                when :rparen, :lrparen
                  convert_to_matrix({:type => :paren, :e => e, :lparen => t1[:value], :rparen => t2[:value]})
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
        when :accent
          s = unwrap_paren(parse_simple_expression(tok, depth))
          unary(t1[:value], s)
        when :unary
          s = unwrap_paren(parse_simple_expression(tok, depth))
          unary(t1[:value], s)
        when :font
          s = unwrap_paren(parse_simple_expression(tok, depth))
          unary(t1[:value], s)
        when :func
          s = parse_simple_expression(tok, depth)
          if t1[:wrap_left] || t1[:wrap_right]
            paren(t1[:wrap_left], s, t1[:wrap_right], :no_unwrap => true)
          else
            unary(t1[:value], s)
          end
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
      if expression.is_a?(Hash) && expression[:type] == :paren && !expression[:no_unwrap]
        expression[:e]
      else
        expression
      end
    end

    def convert_to_matrix(expression)
      return expression unless expression.is_a?(Hash) && expression[:type] == :paren && expression[:e].is_a?(Array)

      rows, separators = expression[:e].partition.with_index { |obj, i| i.even? }
      return expression unless rows.length > 1 &&
          rows.length > separators.length &&
          separators.all? { |item| is_matrix_separator(item) } &&
          (rows.all? { |item| item[:type] == :paren && item[:lparen] == :lparen && item[:rparen] == :rparen } ||
              rows.all? { |item| item[:type] == :paren && item[:lparen] == :lbracket && item[:rparen] == :rbracket })

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
