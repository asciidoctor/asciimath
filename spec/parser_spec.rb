#encoding: utf-8
require 'rspec'
require 'asciimath'
require 'asciimath/ast'

include AsciiMath::AST

def should_generate(expected_output)
  Proc.new { |example|
    asciimath = example.description
    parsed = AsciiMath.parse(asciimath)
    variant = example.metadata[:variant]
    if variant
      expected = expected_output[variant]
      if expected
        case variant
          when :ast
            expect(parsed.ast).to eq(expected)
          when :mathml
            expect(parsed.to_mathml).to eq(expected)
          when :html
            expect(parsed.to_html).to eq(expected)
          when :latex
            expect(parsed.to_latex).to eq(expected)
          else
            skip("Unsupported output variant '#{variant}'")
        end
      else
        skip("No example output provided for '#{variant}'")
      end
    else
      skip("No known output variant found")
    end
  }
end

RSpec.shared_examples "AsciiMath Examples" do
  example('underset(_)(hat A) = hat A exp j vartheta_0', &should_generate(
      :ast => expression(
          binary(
              :underset,
              :sub,
              unary(:hat, "A")
          ),
          :eq,
          unary(:hat, "A"),
          :exp,
          "j",
          sub(:vartheta, "0")
      )
  ))

  example('x+b/(2a)<+-sqrt((b^2)/(4a^2)-c/a)', &should_generate(
      :ast => expression(
          "x",
          :plus,
          binary(:frac, "b", expression("2", "a")),
          :lt,
          :pm,
          unary(
              :sqrt,
              expression(
                  binary(
                      :frac,
                      sup("b", "2"),
                      expression("4", sup("a", "2"))
                  ),
                  :minus,
                  binary(:frac, "c", "a")
              )
          )
      ),
      :mathml => '<math><mi>x</mi><mo>+</mo><mfrac><mi>b</mi><mrow><mn>2</mn><mi>a</mi></mrow></mfrac><mo>&lt;</mo><mo>&#xB1;</mo><msqrt><mrow><mfrac><msup><mi>b</mi><mn>2</mn></msup><mrow><mn>4</mn><msup><mi>a</mi><mn>2</mn></msup></mrow></mfrac><mo>&#x2212;</mo><mfrac><mi>c</mi><mi>a</mi></mfrac></mrow></msqrt></math>',
      :html => nil,
      :latex => 'x + \\frac{b}{2 a} < \\pm \\sqrt{\\frac{b^2}{4 a^2} - \\frac{c}{a}}',
  ))

  example('a^2 + b^2 = c^2', &should_generate(
      :ast => expression(
          sup("a", "2"),
          :plus,
          sup("b", "2"),
          :eq,
          sup("c", "2")
      ),
      :mathml => '<math><msup><mi>a</mi><mn>2</mn></msup><mo>+</mo><msup><mi>b</mi><mn>2</mn></msup><mo>=</mo><msup><mi>c</mi><mn>2</mn></msup></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-identifier">a</span><span class="math-subsup"><span class="math-smaller"><span class="math-number">2</span></span><span class="math-smaller">&#x200D;</span></span><span class="math-operator">+</span><span class="math-identifier">b</span><span class="math-subsup"><span class="math-smaller"><span class="math-number">2</span></span><span class="math-smaller">&#x200D;</span></span><span class="math-operator">=</span><span class="math-identifier">c</span><span class="math-subsup"><span class="math-smaller"><span class="math-number">2</span></span><span class="math-smaller">&#x200D;</span></span></span></span>',
      :latex => 'a^2 + b^2 = c^2',

  ))

  example('x = (-b+-sqrt(b^2-4ac))/(2a)', &should_generate(
      :ast => expression(
          "x",
          :eq,
          binary(
              :frac,
              expression(
                  :minus, "b",
                  :pm,
                  unary(:sqrt, expression(sup("b", "2"), :minus, "4", "a", "c"))
              ),
              expression("2", "a"),
          )
      ),
      :mathml => '<math><mi>x</mi><mo>=</mo><mfrac><mrow><mo>&#x2212;</mo><mi>b</mi><mo>&#xB1;</mo><msqrt><mrow><msup><mi>b</mi><mn>2</mn></msup><mn>-4</mn><mi>a</mi><mi>c</mi></mrow></msqrt></mrow><mrow><mn>2</mn><mi>a</mi></mrow></mfrac></math>',
      :html => nil,
      :latex => 'x = \\frac{- b \\pm \\sqrt{b^2 -4 a c}}{2 a}',
  ))

  example('m = (y_2 - y_1)/(x_2 - x_1) = (Deltay)/(Deltax)', &should_generate(
      :ast => expression(
          "m",
          :eq,
          binary(:frac, expression(sub("y", "2"), :minus, sub("y", "1")), expression(sub("x", "2"), :minus, sub("x", "1"))),
          :eq,
          binary(:frac, expression(:Delta, "y"), expression(:Delta, "x")),
      ),
      :mathml => '<math><mi>m</mi><mo>=</mo><mfrac><mrow><msub><mi>y</mi><mn>2</mn></msub><mo>&#x2212;</mo><msub><mi>y</mi><mn>1</mn></msub></mrow><mrow><msub><mi>x</mi><mn>2</mn></msub><mo>&#x2212;</mo><msub><mi>x</mi><mn>1</mn></msub></mrow></mfrac><mo>=</mo><mfrac><mrow><mo>&#x394;</mo><mi>y</mi></mrow><mrow><mo>&#x394;</mo><mi>x</mi></mrow></mfrac></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-identifier">m</span><span class="math-operator">=</span><span class="math-blank">&#x200D;</span><span class="math-fraction"><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-identifier">y</span><span class="math-subsup"><span class="math-smaller">&#x200D;</span><span class="math-smaller"><span class="math-number">2</span></span></span><span class="math-operator">&#x2212;</span><span class="math-identifier">y</span><span class="math-subsup"><span class="math-smaller">&#x200D;</span><span class="math-smaller"><span class="math-number">1</span></span></span></span></span></span></span></span><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-identifier">x</span><span class="math-subsup"><span class="math-smaller">&#x200D;</span><span class="math-smaller"><span class="math-number">2</span></span></span><span class="math-operator">&#x2212;</span><span class="math-identifier">x</span><span class="math-subsup"><span class="math-smaller">&#x200D;</span><span class="math-smaller"><span class="math-number">1</span></span></span></span></span></span></span></span></span><span class="math-operator">=</span><span class="math-blank">&#x200D;</span><span class="math-fraction"><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-operator">&#x394;</span><span class="math-identifier">y</span></span></span></span></span></span><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-operator">&#x394;</span><span class="math-identifier">x</span></span></span></span></span></span></span></span></span>',
      :latex => 'm = \\frac{y_2 - y_1}{x_2 - x_1} = \\frac{\\Delta y}{\\Delta x}',
  ))

  example('f\'(x) = lim_(Deltax->0)(f(x+Deltax)-f(x))/(Deltax)', &should_generate(
      :ast => expression(
          :f,
          :prime,
          paren(:lparen, "x", :rparen),
          :eq,
          sub(
              :lim,
              expression(:Delta, "x", :to, "0")
          ),
          binary(
              :frac,
              expression(:f, paren(:lparen, expression("x", :plus, :Delta, "x"), :rparen), :minus, :f, paren(:lparen, "x", :rparen)),
              expression(:Delta, "x")
          )
      ),
      :mathml => '<math><mi>f</mi><mo>&#x2032;</mo><mfenced open="(" close=")"><mi>x</mi></mfenced><mo>=</mo><munder><mo>lim</mo><mrow><mo>&#x394;</mo><mi>x</mi><mo>&#x2192;</mo><mn>0</mn></mrow></munder><mfrac><mrow><mi>f</mi><mfenced open="(" close=")"><mrow><mi>x</mi><mo>+</mo><mo>&#x394;</mo><mi>x</mi></mrow></mfenced><mo>&#x2212;</mo><mi>f</mi><mfenced open="(" close=")"><mi>x</mi></mfenced></mrow><mrow><mo>&#x394;</mo><mi>x</mi></mrow></mfrac></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-identifier">f</span><span class="math-operator">&#x2032;</span><span class="math-row"><span class="math-brace">(</span><span class="math-row"><span class="math-identifier">x</span></span><span class="math-brace">)</span></span><span class="math-operator">=</span><span class="math-blank">&#x200D;</span><span class="math-underover"><span class="math-smaller"><span class="math-blank">&#x200D;</span></span><span class="math-operator">lim</span><span class="math-smaller"><span class="math-row"><span class="math-operator">&#x394;</span><span class="math-identifier">x</span><span class="math-operator">&#x2192;</span><span class="math-number">0</span></span></span></span><span class="math-blank">&#x200D;</span><span class="math-fraction"><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-identifier">f</span><span class="math-row"><span class="math-brace">(</span><span class="math-row"><span class="math-identifier">x</span><span class="math-operator">+</span><span class="math-operator">&#x394;</span><span class="math-identifier">x</span></span><span class="math-brace">)</span></span><span class="math-operator">&#x2212;</span><span class="math-identifier">f</span><span class="math-row"><span class="math-brace">(</span><span class="math-row"><span class="math-identifier">x</span></span><span class="math-brace">)</span></span></span></span></span></span></span><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-operator">&#x394;</span><span class="math-identifier">x</span></span></span></span></span></span></span></span></span>',
      :latex => 'f \' \\left ( x \\right ) = \\lim_{\\Delta x \\rightarrow 0} \\frac{f \\left ( x + \\Delta x \\right ) - f \\left ( x \\right )}{\\Delta x}',
  ))

  example('d/dx [x^n] = nx^(n - 1)', &should_generate(
      :mathml => '<math><mfrac><mi>d</mi><mi>dx</mi></mfrac><mfenced open="[" close="]"><msup><mi>x</mi><mi>n</mi></msup></mfenced><mo>=</mo><mi>n</mi><msup><mi>x</mi><mrow><mi>n</mi><mo>&#x2212;</mo><mn>1</mn></mrow></msup></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-blank">&#x200D;</span><span class="math-fraction"><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-identifier">d</span></span></span></span></span><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-identifier">dx</span></span></span></span></span></span><span class="math-row"><span class="math-brace">[</span><span class="math-row"><span class="math-identifier">x</span><span class="math-subsup"><span class="math-smaller"><span class="math-identifier">n</span></span><span class="math-smaller">&#x200D;</span></span></span><span class="math-brace">]</span></span><span class="math-operator">=</span><span class="math-identifier">n</span><span class="math-identifier">x</span><span class="math-subsup"><span class="math-smaller"><span class="math-row"><span class="math-identifier">n</span><span class="math-operator">&#x2212;</span><span class="math-number">1</span></span></span><span class="math-smaller">&#x200D;</span></span></span></span>',
      :latex => '\\frac{d}{dx} \\left [ x^n \\right ] = n x^{n - 1}',
  ))

  example('int_a^b f(x) dx = [F(x)]_a^b = F(b) - F(a)', &should_generate(
      :mathml => '<math><msubsup><mo>&#x222B;</mo><mi>a</mi><mi>b</mi></msubsup><mi>f</mi><mfenced open="(" close=")"><mi>x</mi></mfenced><mi>dx</mi><mo>=</mo><msubsup><mfenced open="[" close="]"><mrow><mi>F</mi><mfenced open="(" close=")"><mi>x</mi></mfenced></mrow></mfenced><mi>a</mi><mi>b</mi></msubsup><mo>=</mo><mi>F</mi><mfenced open="(" close=")"><mi>b</mi></mfenced><mo>&#x2212;</mo><mi>F</mi><mfenced open="(" close=")"><mi>a</mi></mfenced></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-operator">&#x222B;</span><span class="math-subsup"><span class="math-smaller"><span class="math-identifier">b</span></span><span class="math-smaller"><span class="math-identifier">a</span></span></span><span class="math-identifier">f</span><span class="math-row"><span class="math-brace">(</span><span class="math-row"><span class="math-identifier">x</span></span><span class="math-brace">)</span></span><span class="math-identifier">dx</span><span class="math-operator">=</span><span class="math-row"><span class="math-brace">[</span><span class="math-row"><span class="math-identifier">F</span><span class="math-row"><span class="math-brace">(</span><span class="math-row"><span class="math-identifier">x</span></span><span class="math-brace">)</span></span></span><span class="math-brace">]</span></span><span class="math-subsup"><span class="math-smaller"><span class="math-identifier">b</span></span><span class="math-smaller"><span class="math-identifier">a</span></span></span><span class="math-operator">=</span><span class="math-identifier">F</span><span class="math-row"><span class="math-brace">(</span><span class="math-row"><span class="math-identifier">b</span></span><span class="math-brace">)</span></span><span class="math-operator">&#x2212;</span><span class="math-identifier">F</span><span class="math-row"><span class="math-brace">(</span><span class="math-row"><span class="math-identifier">a</span></span><span class="math-brace">)</span></span></span></span>',
      :latex => '\\int_a^b f \\left ( x \\right ) dx = \\left [ F \\left ( x \\right ) \\right ]_a^b = F \\left ( b \\right ) - F \\left ( a \\right )',
  ))

  example('int_a^b f(x) dx = f(c)(b - a)', &should_generate(
      :mathml => '<math><msubsup><mo>&#x222B;</mo><mi>a</mi><mi>b</mi></msubsup><mi>f</mi><mfenced open="(" close=")"><mi>x</mi></mfenced><mi>dx</mi><mo>=</mo><mi>f</mi><mfenced open="(" close=")"><mi>c</mi></mfenced><mfenced open="(" close=")"><mrow><mi>b</mi><mo>&#x2212;</mo><mi>a</mi></mrow></mfenced></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-operator">&#x222B;</span><span class="math-subsup"><span class="math-smaller"><span class="math-identifier">b</span></span><span class="math-smaller"><span class="math-identifier">a</span></span></span><span class="math-identifier">f</span><span class="math-row"><span class="math-brace">(</span><span class="math-row"><span class="math-identifier">x</span></span><span class="math-brace">)</span></span><span class="math-identifier">dx</span><span class="math-operator">=</span><span class="math-identifier">f</span><span class="math-row"><span class="math-brace">(</span><span class="math-row"><span class="math-identifier">c</span></span><span class="math-brace">)</span></span><span class="math-row"><span class="math-brace">(</span><span class="math-row"><span class="math-identifier">b</span><span class="math-operator">&#x2212;</span><span class="math-identifier">a</span></span><span class="math-brace">)</span></span></span></span>',
      :latex => '\\int_a^b f \\left ( x \\right ) dx = f \\left ( c \\right ) \\left ( b - a \\right )',
  ))

  example('ax^2 + bx + c = 0', &should_generate(
      :mathml => '<math><mi>a</mi><msup><mi>x</mi><mn>2</mn></msup><mo>+</mo><mi>b</mi><mi>x</mi><mo>+</mo><mi>c</mi><mo>=</mo><mn>0</mn></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-identifier">a</span><span class="math-identifier">x</span><span class="math-subsup"><span class="math-smaller"><span class="math-number">2</span></span><span class="math-smaller">&#x200D;</span></span><span class="math-operator">+</span><span class="math-identifier">b</span><span class="math-identifier">x</span><span class="math-operator">+</span><span class="math-identifier">c</span><span class="math-operator">=</span><span class="math-number">0</span></span></span>',
      :latex => 'a x^2 + b x + c = 0',
  ))

  example('"average value"=1/(b-a) int_a^b f(x) dx', &should_generate(
      :mathml => '<math><mtext>average value</mtext><mo>=</mo><mfrac><mn>1</mn><mrow><mi>b</mi><mo>&#x2212;</mo><mi>a</mi></mrow></mfrac><msubsup><mo>&#x222B;</mo><mi>a</mi><mi>b</mi></msubsup><mi>f</mi><mfenced open="(" close=")"><mi>x</mi></mfenced><mi>dx</mi></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-text">average value</span><span class="math-operator">=</span><span class="math-blank">&#x200D;</span><span class="math-fraction"><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-number">1</span></span></span></span></span><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-identifier">b</span><span class="math-operator">&#x2212;</span><span class="math-identifier">a</span></span></span></span></span></span></span><span class="math-operator">&#x222B;</span><span class="math-subsup"><span class="math-smaller"><span class="math-identifier">b</span></span><span class="math-smaller"><span class="math-identifier">a</span></span></span><span class="math-identifier">f</span><span class="math-row"><span class="math-brace">(</span><span class="math-row"><span class="math-identifier">x</span></span><span class="math-brace">)</span></span><span class="math-identifier">dx</span></span></span>',
      :latex => '\\text{average value} = \\frac{1}{b - a} \\int_a^b f \\left ( x \\right ) dx',
  ))

  example('d/dx[int_a^x f(t) dt] = f(x)', &should_generate(
      :mathml => '<math><mfrac><mi>d</mi><mi>dx</mi></mfrac><mfenced open="[" close="]"><mrow><msubsup><mo>&#x222B;</mo><mi>a</mi><mi>x</mi></msubsup><mi>f</mi><mfenced open="(" close=")"><mi>t</mi></mfenced><mi>dt</mi></mrow></mfenced><mo>=</mo><mi>f</mi><mfenced open="(" close=")"><mi>x</mi></mfenced></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-blank">&#x200D;</span><span class="math-fraction"><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-identifier">d</span></span></span></span></span><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-identifier">dx</span></span></span></span></span></span><span class="math-row"><span class="math-brace">[</span><span class="math-row"><span class="math-operator">&#x222B;</span><span class="math-subsup"><span class="math-smaller"><span class="math-identifier">x</span></span><span class="math-smaller"><span class="math-identifier">a</span></span></span><span class="math-identifier">f</span><span class="math-row"><span class="math-brace">(</span><span class="math-row"><span class="math-identifier">t</span></span><span class="math-brace">)</span></span><span class="math-identifier">dt</span></span><span class="math-brace">]</span></span><span class="math-operator">=</span><span class="math-identifier">f</span><span class="math-row"><span class="math-brace">(</span><span class="math-row"><span class="math-identifier">x</span></span><span class="math-brace">)</span></span></span></span>',
      :latex => '\frac{d}{dx} \\left [ \\int_a^x f \\left ( t \\right ) dt \\right ] = f \\left ( x \\right )',
  ))

  example('hat(ab) bar(xy) ul(A) vec(v)', &should_generate(
      :mathml => '<math><mover><mrow><mi>a</mi><mi>b</mi></mrow><mo>^</mo></mover><mover><mrow><mi>x</mi><mi>y</mi></mrow><mo>&#xAF;</mo></mover><munder><mi>A</mi><mo>_</mo></munder><mover><mi>v</mi><mo>&#x2192;</mo></mover></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-blank">&#x200D;</span><span class="math-underover"><span class="math-smaller"><span class="math-operator">^</span></span><span class="math-row"><span class="math-identifier">a</span><span class="math-identifier">b</span></span><span class="math-smaller"><span class="math-blank">&#x200D;</span></span></span><span class="math-blank">&#x200D;</span><span class="math-underover"><span class="math-smaller"><span class="math-operator">&#xAF;</span></span><span class="math-row"><span class="math-identifier">x</span><span class="math-identifier">y</span></span><span class="math-smaller"><span class="math-blank">&#x200D;</span></span></span><span class="math-blank">&#x200D;</span><span class="math-underover"><span class="math-smaller"><span class="math-blank">&#x200D;</span></span><span class="math-row"><span class="math-identifier">A</span></span><span class="math-smaller"><span class="math-operator">_</span></span></span><span class="math-blank">&#x200D;</span><span class="math-underover"><span class="math-smaller"><span class="math-operator">&#x2192;</span></span><span class="math-row"><span class="math-identifier">v</span></span><span class="math-smaller"><span class="math-blank">&#x200D;</span></span></span></span></span>',
      :latex => '\\hat{a b} \\overline{x y} \\underline{A} \\vec{v}',
  ))

  example('z_12^34', &should_generate(
      :mathml => '<math><msubsup><mi>z</mi><mn>12</mn><mn>34</mn></msubsup></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-identifier">z</span><span class="math-subsup"><span class="math-smaller"><span class="math-number">34</span></span><span class="math-smaller"><span class="math-number">12</span></span></span></span></span>',
      :latex => 'z_12^34',
  ))

  example('lim_(x->c)(f(x)-f(c))/(x-c)', &should_generate(
      :mathml => '<math><munder><mo>lim</mo><mrow><mi>x</mi><mo>&#x2192;</mo><mi>c</mi></mrow></munder><mfrac><mrow><mi>f</mi><mfenced open="(" close=")"><mi>x</mi></mfenced><mo>&#x2212;</mo><mi>f</mi><mfenced open="(" close=")"><mi>c</mi></mfenced></mrow><mrow><mi>x</mi><mo>&#x2212;</mo><mi>c</mi></mrow></mfrac></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-blank">&#x200D;</span><span class="math-underover"><span class="math-smaller"><span class="math-blank">&#x200D;</span></span><span class="math-operator">lim</span><span class="math-smaller"><span class="math-row"><span class="math-identifier">x</span><span class="math-operator">&#x2192;</span><span class="math-identifier">c</span></span></span></span><span class="math-blank">&#x200D;</span><span class="math-fraction"><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-identifier">f</span><span class="math-row"><span class="math-brace">(</span><span class="math-row"><span class="math-identifier">x</span></span><span class="math-brace">)</span></span><span class="math-operator">&#x2212;</span><span class="math-identifier">f</span><span class="math-row"><span class="math-brace">(</span><span class="math-row"><span class="math-identifier">c</span></span><span class="math-brace">)</span></span></span></span></span></span></span><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-identifier">x</span><span class="math-operator">&#x2212;</span><span class="math-identifier">c</span></span></span></span></span></span></span></span></span>',
      :latex => '\\lim_{x \\rightarrow c} \\frac{f \\left ( x \\right ) - f \\left ( c \\right )}{x - c}',
  ))

  example('int_0^(pi/2) g(x) dx', &should_generate(
      :mathml => '<math><msubsup><mo>&#x222B;</mo><mn>0</mn><mfrac><mi>&#x3C0;</mi><mn>2</mn></mfrac></msubsup><mi>g</mi><mfenced open="(" close=")"><mi>x</mi></mfenced><mi>dx</mi></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-operator">&#x222B;</span><span class="math-subsup"><span class="math-smaller"><span class="math-row"><span class="math-blank">&#x200D;</span><span class="math-fraction"><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-identifier">&#x3C0;</span></span></span></span></span><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-number">2</span></span></span></span></span></span></span></span><span class="math-smaller"><span class="math-number">0</span></span></span><span class="math-identifier">g</span><span class="math-row"><span class="math-brace">(</span><span class="math-row"><span class="math-identifier">x</span></span><span class="math-brace">)</span></span><span class="math-identifier">dx</span></span></span>',
      :latex => '\\int_0^{\\frac{\\pi}{2}} g \\left ( x \\right ) dx',
  ))

  example('sum_(n=0)^oo a_n', &should_generate(
      :mathml => '<math><munderover><mo>&#x2211;</mo><mrow><mi>n</mi><mo>=</mo><mn>0</mn></mrow><mo>&#x221E;</mo></munderover><msub><mi>a</mi><mi>n</mi></msub></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-blank">&#x200D;</span><span class="math-underover"><span class="math-smaller"><span class="math-operator">&#x221E;</span></span><span class="math-operator">&#x2211;</span><span class="math-smaller"><span class="math-row"><span class="math-identifier">n</span><span class="math-operator">=</span><span class="math-number">0</span></span></span></span><span class="math-identifier">a</span><span class="math-subsup"><span class="math-smaller">&#x200D;</span><span class="math-smaller"><span class="math-identifier">n</span></span></span></span></span>',
      :latex => '\\sum_{n = 0}^\\infty a_n',
  ))

  example('((1,2,3),(4,5,6),(7,8,9))', &should_generate(
      :mathml => '<math><mfenced open="(" close=")"><mtable><mtr><mtd><mn>1</mn></mtd><mtd><mn>2</mn></mtd><mtd><mn>3</mn></mtd></mtr><mtr><mtd><mn>4</mn></mtd><mtd><mn>5</mn></mtd><mtd><mn>6</mn></mtd></mtr><mtr><mtd><mn>7</mn></mtd><mtd><mn>8</mn></mtd><mtd><mn>9</mn></mtd></mtr></mtable></mfenced></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-row"><span class="math-brace" style="font-size: 300%;">(</span><span class="math-matrix" style="grid-template-columns:repeat(3,1fr);grid-template-rows:repeat(3,1fr);"><span class="math-row"><span class="math-number">1</span></span><span class="math-row"><span class="math-number">2</span></span><span class="math-row"><span class="math-number">3</span></span><span class="math-row"><span class="math-number">4</span></span><span class="math-row"><span class="math-number">5</span></span><span class="math-row"><span class="math-number">6</span></span><span class="math-row"><span class="math-number">7</span></span><span class="math-row"><span class="math-number">8</span></span><span class="math-row"><span class="math-number">9</span></span></span><span class="math-brace" style="font-size: 300%;">)</span></span></span></span>',
      :latex => '\\left ( \\begin{matrix} 1 & 2 & 3 \\\\ 4 & 5 & 6 \\\\ 7 & 8 & 9 \\end{matrix} \\right )',
  ))

  example('|(a,b),(c,d)|=ad-bc', &should_generate(
      :mathml => '<math><mfenced open="|" close="|"><mtable><mtr><mtd><mi>a</mi></mtd><mtd><mi>b</mi></mtd></mtr><mtr><mtd><mi>c</mi></mtd><mtd><mi>d</mi></mtd></mtr></mtable></mfenced><mo>=</mo><mi>a</mi><mi>d</mi><mo>&#x2212;</mo><mi>b</mi><mi>c</mi></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-row"><span class="math-brace" style="font-size: 200%;">|</span><span class="math-matrix" style="grid-template-columns:repeat(2,1fr);grid-template-rows:repeat(2,1fr);"><span class="math-row"><span class="math-identifier">a</span></span><span class="math-row"><span class="math-identifier">b</span></span><span class="math-row"><span class="math-identifier">c</span></span><span class="math-row"><span class="math-identifier">d</span></span></span><span class="math-brace" style="font-size: 200%;">|</span></span><span class="math-operator">=</span><span class="math-identifier">a</span><span class="math-identifier">d</span><span class="math-operator">&#x2212;</span><span class="math-identifier">b</span><span class="math-identifier">c</span></span></span>',
      :latex => '\\left | \\begin{matrix} a & b \\\\ c & d \\end{matrix} \\right | = a d - b c',
  ))

  example('((a_(11), cdots , a_(1n)),(vdots, ddots, vdots),(a_(m1), cdots , a_(mn)))', &should_generate(
      :mathml => '<math><mfenced open="(" close=")"><mtable><mtr><mtd><msub><mi>a</mi><mn>11</mn></msub></mtd><mtd><mo>&#x22EF;</mo></mtd><mtd><msub><mi>a</mi><mrow><mn>1</mn><mi>n</mi></mrow></msub></mtd></mtr><mtr><mtd><mo>&#x22EE;</mo></mtd><mtd><mo>&#x22F1;</mo></mtd><mtd><mo>&#x22EE;</mo></mtd></mtr><mtr><mtd><msub><mi>a</mi><mrow><mi>m</mi><mn>1</mn></mrow></msub></mtd><mtd><mo>&#x22EF;</mo></mtd><mtd><msub><mi>a</mi><mrow><mi>m</mi><mi>n</mi></mrow></msub></mtd></mtr></mtable></mfenced></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-row"><span class="math-brace" style="font-size: 300%;">(</span><span class="math-matrix" style="grid-template-columns:repeat(3,1fr);grid-template-rows:repeat(3,1fr);"><span class="math-row"><span class="math-identifier">a</span><span class="math-subsup"><span class="math-smaller">&#x200D;</span><span class="math-smaller"><span class="math-row"><span class="math-number">11</span></span></span></span></span><span class="math-row"><span class="math-operator">&#x22EF;</span></span><span class="math-row"><span class="math-identifier">a</span><span class="math-subsup"><span class="math-smaller">&#x200D;</span><span class="math-smaller"><span class="math-row"><span class="math-number">1</span><span class="math-identifier">n</span></span></span></span></span><span class="math-row"><span class="math-operator">&#x22EE;</span></span><span class="math-row"><span class="math-operator">&#x22F1;</span></span><span class="math-row"><span class="math-operator">&#x22EE;</span></span><span class="math-row"><span class="math-identifier">a</span><span class="math-subsup"><span class="math-smaller">&#x200D;</span><span class="math-smaller"><span class="math-row"><span class="math-identifier">m</span><span class="math-number">1</span></span></span></span></span><span class="math-row"><span class="math-operator">&#x22EF;</span></span><span class="math-row"><span class="math-identifier">a</span><span class="math-subsup"><span class="math-smaller">&#x200D;</span><span class="math-smaller"><span class="math-row"><span class="math-identifier">m</span><span class="math-identifier">n</span></span></span></span></span></span><span class="math-brace" style="font-size: 300%;">)</span></span></span></span>',
      :latex => '\\left ( \\begin{matrix} a_{11} & \\cdots & a_{1 n} \\\\ \\vdots & \\ddots & \\vdots \\\\ a_{m 1} & \\cdots & a_{m n} \\end{matrix} \\right )',
  ))

  example('sum_(k=1)^n k = 1+2+ cdots +n=(n(n+1))/2', &should_generate(
      :mathml => '<math><munderover><mo>&#x2211;</mo><mrow><mi>k</mi><mo>=</mo><mn>1</mn></mrow><mi>n</mi></munderover><mi>k</mi><mo>=</mo><mn>1</mn><mo>+</mo><mn>2</mn><mo>+</mo><mo>&#x22EF;</mo><mo>+</mo><mi>n</mi><mo>=</mo><mfrac><mrow><mi>n</mi><mfenced open="(" close=")"><mrow><mi>n</mi><mo>+</mo><mn>1</mn></mrow></mfenced></mrow><mn>2</mn></mfrac></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-blank">&#x200D;</span><span class="math-underover"><span class="math-smaller"><span class="math-identifier">n</span></span><span class="math-operator">&#x2211;</span><span class="math-smaller"><span class="math-row"><span class="math-identifier">k</span><span class="math-operator">=</span><span class="math-number">1</span></span></span></span><span class="math-identifier">k</span><span class="math-operator">=</span><span class="math-number">1</span><span class="math-operator">+</span><span class="math-number">2</span><span class="math-operator">+</span><span class="math-operator">&#x22EF;</span><span class="math-operator">+</span><span class="math-identifier">n</span><span class="math-operator">=</span><span class="math-blank">&#x200D;</span><span class="math-fraction"><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-identifier">n</span><span class="math-row"><span class="math-brace">(</span><span class="math-row"><span class="math-identifier">n</span><span class="math-operator">+</span><span class="math-number">1</span></span><span class="math-brace">)</span></span></span></span></span></span></span><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-number">2</span></span></span></span></span></span></span></span>',
      :latex => '\\sum_{k = 1}^n k = 1 + 2 + \\cdots + n = \\frac{n \\left ( n + 1 \\right )}{2}',
  ))

  example('"Скорость"=("Расстояние")/("Время")', &should_generate(
      :mathml => '<math><mtext>&#x421;&#x43A;&#x43E;&#x440;&#x43E;&#x441;&#x442;&#x44C;</mtext><mo>=</mo><mfrac><mtext>&#x420;&#x430;&#x441;&#x441;&#x442;&#x43E;&#x44F;&#x43D;&#x438;&#x435;</mtext><mtext>&#x412;&#x440;&#x435;&#x43C;&#x44F;</mtext></mfrac></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-text">&#x421;&#x43A;&#x43E;&#x440;&#x43E;&#x441;&#x442;&#x44C;</span><span class="math-operator">=</span><span class="math-blank">&#x200D;</span><span class="math-fraction"><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-text">&#x420;&#x430;&#x441;&#x441;&#x442;&#x43E;&#x44F;&#x43D;&#x438;&#x435;</span></span></span></span></span></span><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-text">&#x412;&#x440;&#x435;&#x43C;&#x44F;</span></span></span></span></span></span></span></span></span>',
      :latex => '\\text{Скорость} = \\frac{\\text{Расстояние}}{\\text{Время}}',
  ))

  example('bb (a + b) + cc c = fr (d^n)', &should_generate(
      :mathml => '<math><mstyle mathvariant="bold"><mrow><mi>a</mi><mo>+</mo><mi>b</mi></mrow></mstyle><mo>+</mo><mstyle mathvariant="script"><mi>c</mi></mstyle><mo>=</mo><mstyle mathvariant="fraktur"><msup><mi>d</mi><mi>n</mi></msup></mstyle></math>',
      :html => nil,
      :latex => '\\mathbf{a + b} + \\mathscr{c} = \\mathfrak{d^n}',
  ))

  example('max()', &should_generate(
      :mathml => '<math><mo>max</mo><mfenced open="(" close=")"></mfenced></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-operator">max</span><span class="math-row"><span class="math-brace">(</span><span class="math-brace">)</span></span></span></span>',
      :latex => '\\max \\left (  \\right )',
  ))

  example('text("foo")', &should_generate(
      :mathml => '<math><mtext>"foo"</mtext></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-text">"foo"</span></span></span>',
      :latex => '\\text{"foo"}',
  ))

  example('ubrace(1 + 2) obrace(3 + 4', &should_generate(
      :mathml => '<math><munder><mrow><mn>1</mn><mo>+</mo><mn>2</mn></mrow><mo>&#x23DF;</mo></munder><mover><mrow><mn>3</mn><mo>+</mo><mn>4</mn></mrow><mo>&#x23DE;</mo></mover></math>',
      :latex => '\\underbrace{1 + 2} \\overbrace{3 + 4}',
  ))

  example("s'_i = {(- 1, if s_i > s_(i + 1)),( + 1, if s_i <= s_(i + 1)):}", &should_generate(
      :mathml => '<math><mi>s</mi><msub><mo>&#x2032;</mo><mi>i</mi></msub><mo>=</mo><mfenced open="{" close=""><mtable><mtr><mtd><mrow><mo>&#x2212;</mo><mn>1</mn></mrow></mtd><mtd><mrow><mo>if</mo><msub><mi>s</mi><mi>i</mi></msub><mo>&gt;</mo><msub><mi>s</mi><mrow><mi>i</mi><mo>+</mo><mn>1</mn></mrow></msub></mrow></mtd></mtr><mtr><mtd><mrow><mo>+</mo><mn>1</mn></mrow></mtd><mtd><mrow><mo>if</mo><msub><mi>s</mi><mi>i</mi></msub><mo>&#x2264;</mo><msub><mi>s</mi><mrow><mi>i</mi><mo>+</mo><mn>1</mn></mrow></msub></mrow></mtd></mtr></mtable></mfenced></math>',
      :latex => 's \'_i = \\left \\{ \\begin{matrix} - 1 & \\text{if} s_i > s_{i + 1} \\\\ + 1 & \\text{if} s_i \\leq s_{i + 1} \\end{matrix} \\right .',
  ))

  example("s'_i = {(, if s_i > s_(i + 1)),( + 1,):}", &should_generate(
      :ast => expression(
          "s",
          sub(:prime, "i"),
          :eq,
          matrix(
              :lbrace,
              [
                  [[], [:if, sub("s", "i"), :gt, sub("s", ["i", :plus, "1"])]],
                  [[:plus, "1"], []]
              ],
              nil
          )
      ),
      :mathml => '<math><mi>s</mi><msub><mo>&#x2032;</mo><mi>i</mi></msub><mo>=</mo><mfenced open="{" close=""><mtable><mtr><mtd></mtd><mtd><mrow><mo>if</mo><msub><mi>s</mi><mi>i</mi></msub><mo>&gt;</mo><msub><mi>s</mi><mrow><mi>i</mi><mo>+</mo><mn>1</mn></mrow></msub></mrow></mtd></mtr><mtr><mtd><mrow><mo>+</mo><mn>1</mn></mrow></mtd><mtd></mtd></mtr></mtable></mfenced></math>',
      :latex => 's \'_i = \\left \\{ \\begin{matrix}  & \\text{if} s_i > s_{i + 1} \\\\ + 1 &  \\end{matrix} \\right .',
  ))

  example('{:(a,b),(c,d):}', &should_generate(
      :mathml => '<math><mtable><mtr><mtd><mi>a</mi></mtd><mtd><mi>b</mi></mtd></mtr><mtr><mtd><mi>c</mi></mtd><mtd><mi>d</mi></mtd></mtr></mtable></math>',
      :latex => '\\begin{matrix} a & b \\\\ c & d \\end{matrix}',
  ))

  example('overset (a + b) (c + d)', &should_generate(
      :mathml => '<math><mover><mrow><mi>c</mi><mo>+</mo><mi>d</mi></mrow><mrow><mi>a</mi><mo>+</mo><mi>b</mi></mrow></mover></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-blank">&#x200D;</span><span class="math-underover"><span class="math-smaller"><span class="math-row"><span class="math-identifier">a</span><span class="math-operator">+</span><span class="math-identifier">b</span></span></span><span class="math-row"><span class="math-identifier">c</span><span class="math-operator">+</span><span class="math-identifier">d</span></span><span class="math-smaller"><span class="math-blank">&#x200D;</span></span></span></span></span>',
      :overset => '\\overset{a + b}{c + d}',
  ))

  example('underset a b', &should_generate(
      :mathml => '<math><munder><mi>b</mi><mi>a</mi></munder></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-blank">&#x200D;</span><span class="math-underover"><span class="math-smaller"><span class="math-blank">&#x200D;</span></span><span class="math-identifier">b</span><span class="math-smaller"><span class="math-identifier">a</span></span></span></span></span>',
      :latex => '\\underset{a}{b}',
  ))

  example('sin a_c^b', &should_generate(
      :mathml => '<math><msubsup><mrow><mi>sin</mi><mi>a</mi></mrow><mi>c</mi><mi>b</mi></msubsup></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-row"><span class="math-identifier">sin</span><span class="math-identifier">a</span></span><span class="math-subsup"><span class="math-smaller"><span class="math-identifier">b</span></span><span class="math-smaller"><span class="math-identifier">c</span></span></span></span></span>',
      :latex => '\\sin a_c^b',
  ))

  example('max a_c^b', &should_generate(
      :mathml => '<math><mo>max</mo><msubsup><mi>a</mi><mi>c</mi><mi>b</mi></msubsup></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-operator">max</span><span class="math-identifier">a</span><span class="math-subsup"><span class="math-smaller"><span class="math-identifier">b</span></span><span class="math-smaller"><span class="math-identifier">c</span></span></span></span></span>',
      :latex => '\\max a_c^b',
  ))

  example('norm a_c^b', &should_generate(
      :mathml => '<math><msubsup><mfenced open="&#x2225;" close="&#x2225;"><mi>a</mi></mfenced><mi>c</mi><mi>b</mi></msubsup></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-row"><span class="math-brace">&#x2225;</span><span class="math-identifier">a</span><span class="math-brace">&#x2225;</span></span><span class="math-subsup"><span class="math-smaller"><span class="math-identifier">b</span></span><span class="math-smaller"><span class="math-identifier">c</span></span></span></span></span>',
      :latex => '\\left \\parallel a \\right \\parallel_c^b',
  ))

  example('overarc a_b^c', &should_generate(
      :mathml => '<math><msubsup><mover><mi>a</mi><mo>&#x23DC;</mo></mover><mi>b</mi><mi>c</mi></msubsup></math>',
      :latex => nil,
  ))

  example('frown a_b^c', &should_generate(
      :mathml => '<math><mo>&#x2322;</mo><msubsup><mi>a</mi><mi>b</mi><mi>c</mi></msubsup></math>',
      :latex => '\\frown a_b^c',
  ))

  example('sin(a_c^b)', &should_generate(
      :mathml => '<math><mrow><mi>sin</mi><mfenced open="(" close=")"><msubsup><mi>a</mi><mi>c</mi><mi>b</mi></msubsup></mfenced></mrow></math>',
      :latex => '\\sin \\left ( a_c^b \\right )',
  ))

  version = RUBY_VERSION.split('.').map { |s| s.to_i }

  if version[0] > 1 || version[1] > 8
    example('Скорость=(Расстояние)/(Время)', &should_generate(
        :mathml => '<math><mi>&#x421;</mi><mi>&#x43A;</mi><mi>&#x43E;</mi><mi>&#x440;</mi><mi>&#x43E;</mi><mi>&#x441;</mi><mi>&#x442;</mi><mi>&#x44C;</mi><mo>=</mo><mfrac><mrow><mi>&#x420;</mi><mi>&#x430;</mi><mi>&#x441;</mi><mi>&#x441;</mi><mi>&#x442;</mi><mi>&#x43E;</mi><mi>&#x44F;</mi><mi>&#x43D;</mi><mi>&#x438;</mi><mi>&#x435;</mi></mrow><mrow><mi>&#x412;</mi><mi>&#x440;</mi><mi>&#x435;</mi><mi>&#x43C;</mi><mi>&#x44F;</mi></mrow></mfrac></math>',
        :html => '<span class="math-inline"><span class="math-row"><span class="math-identifier">&#x421;</span><span class="math-identifier">&#x43A;</span><span class="math-identifier">&#x43E;</span><span class="math-identifier">&#x440;</span><span class="math-identifier">&#x43E;</span><span class="math-identifier">&#x441;</span><span class="math-identifier">&#x442;</span><span class="math-identifier">&#x44C;</span><span class="math-operator">=</span><span class="math-blank">&#x200D;</span><span class="math-fraction"><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-identifier">&#x420;</span><span class="math-identifier">&#x430;</span><span class="math-identifier">&#x441;</span><span class="math-identifier">&#x441;</span><span class="math-identifier">&#x442;</span><span class="math-identifier">&#x43E;</span><span class="math-identifier">&#x44F;</span><span class="math-identifier">&#x43D;</span><span class="math-identifier">&#x438;</span><span class="math-identifier">&#x435;</span></span></span></span></span></span><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-identifier">&#x412;</span><span class="math-identifier">&#x440;</span><span class="math-identifier">&#x435;</span><span class="math-identifier">&#x43C;</span><span class="math-identifier">&#x44F;</span></span></span></span></span></span></span></span></span>',
    ))
  end
end

describe "AsciiMath::Parser", :variant => :ast do
  include_examples "AsciiMath Examples"
end

describe "AsciiMath::MathMLBuilder", :variant => :mathml, :skip => "Temporarily disabled" do
  include_examples "AsciiMath Examples"
end

describe "AsciiMath::HTMLBuilder", :variant => :html, :skip => "Temporarily disabled" do
  include_examples "AsciiMath Examples", :html
end

describe "AsciiMath::LatexBuilder", :variant => :latex, :skip => "Temporarily disabled" do
  include_examples "AsciiMath Examples"
end