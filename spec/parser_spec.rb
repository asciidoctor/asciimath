#encoding: utf-8
require 'rspec'
require 'asciimath'
require_relative 'ast'
require 'nokogiri'


module Xml
  def self.mathml2_xsd
    @schema ||= File.open(File.expand_path('../schema/mathml2/mathml2.xsd', __FILE__)) { |io| Nokogiri::XML::Schema(io) }
  end

  def self.mathml3_xsd
    @schema ||= File.open(File.expand_path('../schema/mathml3/mathml3.xsd', __FILE__)) { |io| Nokogiri::XML::Schema(io) }
  end

  def self.parse(content)
    Nokogiri::XML(content)
  end
end

def should_generate(expected_output)
  Proc.new { |example|
    parsed = AsciiMath.parse(example.description)
    variant = example.metadata[:variant]
    if variant
      if expected_output.key?(variant)
        expected = expected_output[variant]
        case variant
          when :ast
            expect(parsed.ast).to eq(expected)
          when :mathml
            expect(parsed.to_mathml).to eq(expected)
            xml_dom = Xml.parse(parsed.to_mathml(:xmlns => 'http://www.w3.org/1998/Math/MathML'))
            Xml.mathml2_xsd.validate(xml_dom).each do |error|
              fail(error.message)
            end
            Xml.mathml3_xsd.validate(xml_dom).each do |error|
              fail(error.message)
            end
          when :mathml_word
            expect(::AsciiMath::MathMLBuilder.new(:msword => true).append_expression(parsed.ast).to_s).to eq(expected)
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
      skip('No known output variant found')
    end
  }
end

RSpec.shared_examples 'AsciiMath Examples' do
  class << self
    include ::AsciiMath::ASTHelper
  end

  example('underset(_)(hat A) = hat A exp j vartheta_0', &should_generate(
      :ast => seq(
          binary(
              symbol('underset'),
              group(symbol('_')),
              group(unary(symbol('hat'), 'A'))
          ),
          symbol('='),
          unary(symbol('hat'), 'A'),
          symbol('exp'),
          'j',
          sub(symbol('vartheta'), '0')
      ),
      :mathml => '<math><munder><mover accent="true"><mi>A</mi><mo>^</mo></mover><mo>_</mo></munder><mo>=</mo><mover accent="true"><mi>A</mi><mo>^</mo></mover><mi>exp</mi><mi>j</mi><msub><mi>&#x3D1;</mi><mn>0</mn></msub></math>',
      :mathml_word => '<math><munder><mrow><mover accent="true"><mrow><mi>A</mi></mrow><mrow><mo>^</mo></mrow></mover></mrow><mrow><mo>_</mo></mrow></munder><mo>=</mo><mover accent="true"><mrow><mi>A</mi></mrow><mrow><mo>^</mo></mrow></mover><mi>exp</mi><mi>j</mi><msub><mrow><mi>&#x3D1;</mi></mrow><mrow><mn>0</mn></mrow></msub></math>',
      :latex => '\\underset{\\text{–}}{\\hat{A}} = \\hat{A} \\exp j \\vartheta_0'
  ))

  example('x+b/(2a)<+-sqrt((b^2)/(4a^2)-c/a)', &should_generate(
      :ast => seq(
          'x',
          symbol('+'),
          infix('b', symbol('/'), grseq('2', 'a')),
          symbol('<'),
          symbol('+-'),
          unary(
              symbol('sqrt'),
              grseq(
                  infix(
                      group(sup('b', '2')),
                      symbol('/'),
                      grseq('4', sup('a', '2'))
                  ),
                  symbol('-'),
                  infix('c', symbol('/'), 'a')
              )
          )
      ),
      :mathml => '<math><mi>x</mi><mo>+</mo><mfrac><mi>b</mi><mrow><mn>2</mn><mi>a</mi></mrow></mfrac><mo>&lt;</mo><mo>&#xB1;</mo><msqrt><mrow><mfrac><msup><mi>b</mi><mn>2</mn></msup><mrow><mn>4</mn><msup><mi>a</mi><mn>2</mn></msup></mrow></mfrac><mo>&#x2212;</mo><mfrac><mi>c</mi><mi>a</mi></mfrac></mrow></msqrt></math>',
      :latex => 'x + \\frac{b}{2 a} < \\pm \\sqrt{\\frac{b^2}{4 a^2} - \\frac{c}{a}}',
  ))

  example('a^2 + b^2 = c^2', &should_generate(
      :ast => seq(
          sup('a', '2'),
          symbol('+'),
          sup('b', '2'),
          symbol('='),
          sup('c', '2')
      ),
      :mathml => '<math><msup><mi>a</mi><mn>2</mn></msup><mo>+</mo><msup><mi>b</mi><mn>2</mn></msup><mo>=</mo><msup><mi>c</mi><mn>2</mn></msup></math>',
      :html => '<span class="math-inline"><span class="math-identifier">a</span><span class="math-subsup"><span class="math-smaller"><span class="math-number">2</span></span><span class="math-smaller">&#x200D;</span></span><span class="math-operator">+</span><span class="math-identifier">b</span><span class="math-subsup"><span class="math-smaller"><span class="math-number">2</span></span><span class="math-smaller">&#x200D;</span></span><span class="math-operator">=</span><span class="math-identifier">c</span><span class="math-subsup"><span class="math-smaller"><span class="math-number">2</span></span><span class="math-smaller">&#x200D;</span></span></span>',
      :latex => 'a^2 + b^2 = c^2',

  ))

  example('x = (-b+-sqrt(b^2-4ac))/(2a)', &should_generate(
      :ast => seq(
          'x',
          symbol('='),
          infix(
              grseq(
                  symbol('-'), 'b',
                  symbol('+-'),
                  unary(symbol('sqrt'), grseq(sup('b', '2'), symbol('-'), '4', 'a', 'c'))
              ),
              symbol('/'),
              grseq('2', 'a'),
          )
      ),
      :mathml => '<math><mi>x</mi><mo>=</mo><mfrac><mrow><mo>&#x2212;</mo><mi>b</mi><mo>&#xB1;</mo><msqrt><mrow><msup><mi>b</mi><mn>2</mn></msup><mo>&#x2212;</mo><mn>4</mn><mi>a</mi><mi>c</mi></mrow></msqrt></mrow><mrow><mn>2</mn><mi>a</mi></mrow></mfrac></math>',
      :latex => 'x = \\frac{- b \\pm \\sqrt{b^2 - 4 a c}}{2 a}',
  ))

  example('m = (y_2 - y_1)/(x_2 - x_1) = (Deltay)/(Deltax)', &should_generate(
      :ast => seq(
          'm',
          symbol('='),
          infix(grseq(sub('y', '2'), symbol('-'), sub('y', '1')), symbol('/'), grseq(sub('x', '2'), symbol('-'), sub('x', '1'))),
          symbol('='),
          infix(grseq(symbol('Delta'), 'y'), symbol('/'), grseq(symbol('Delta'), 'x')),
      ),
      :mathml => '<math><mi>m</mi><mo>=</mo><mfrac><mrow><msub><mi>y</mi><mn>2</mn></msub><mo>&#x2212;</mo><msub><mi>y</mi><mn>1</mn></msub></mrow><mrow><msub><mi>x</mi><mn>2</mn></msub><mo>&#x2212;</mo><msub><mi>x</mi><mn>1</mn></msub></mrow></mfrac><mo>=</mo><mfrac><mrow><mo>&#x394;</mo><mi>y</mi></mrow><mrow><mo>&#x394;</mo><mi>x</mi></mrow></mfrac></math>',
      :html => '<span class="math-inline"><span class="math-identifier">m</span><span class="math-operator">=</span><span class="math-blank">&#x200D;</span><span class="math-fraction"><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-identifier">y</span><span class="math-subsup"><span class="math-smaller">&#x200D;</span><span class="math-smaller"><span class="math-number">2</span></span></span><span class="math-operator">&#x2212;</span><span class="math-identifier">y</span><span class="math-subsup"><span class="math-smaller">&#x200D;</span><span class="math-smaller"><span class="math-number">1</span></span></span></span></span></span></span></span><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-identifier">x</span><span class="math-subsup"><span class="math-smaller">&#x200D;</span><span class="math-smaller"><span class="math-number">2</span></span></span><span class="math-operator">&#x2212;</span><span class="math-identifier">x</span><span class="math-subsup"><span class="math-smaller">&#x200D;</span><span class="math-smaller"><span class="math-number">1</span></span></span></span></span></span></span></span></span><span class="math-operator">=</span><span class="math-blank">&#x200D;</span><span class="math-fraction"><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-operator">&#x394;</span><span class="math-identifier">y</span></span></span></span></span></span><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-operator">&#x394;</span><span class="math-identifier">x</span></span></span></span></span></span></span></span>',
      :latex => 'm = \\frac{y_2 - y_1}{x_2 - x_1} = \\frac{\\Delta y}{\\Delta x}',
  ))

  example('f\'(x) = lim_(Deltax->0)(f(x+Deltax)-f(x))/(Deltax)', &should_generate(
      :ast => seq(
          symbol('f'),
          symbol('\''),
          paren('x'),
          symbol('='),
          sub(
              symbol('lim'),
              grseq(symbol('Delta'), 'x', symbol('->'), '0')
          ),
          infix(
              grseq(symbol('f'), paren(seq('x', symbol('+'), symbol('Delta'), 'x')), symbol('-'), symbol('f'), paren('x')),
              symbol('/'),
              grseq(symbol('Delta'), 'x')
          )
      ),
      :mathml => '<math><mi>f</mi><mo>&#x2032;</mo><mrow><mo>(</mo><mi>x</mi><mo>)</mo></mrow><mo>=</mo><munder><mo>lim</mo><mrow><mo>&#x394;</mo><mi>x</mi><mo>&#x2192;</mo><mn>0</mn></mrow></munder><mfrac><mrow><mi>f</mi><mrow><mo>(</mo><mrow><mi>x</mi><mo>+</mo><mo>&#x394;</mo><mi>x</mi></mrow><mo>)</mo></mrow><mo>&#x2212;</mo><mi>f</mi><mrow><mo>(</mo><mi>x</mi><mo>)</mo></mrow></mrow><mrow><mo>&#x394;</mo><mi>x</mi></mrow></mfrac></math>',
      :html => '<span class="math-inline"><span class="math-identifier">f</span><span class="math-operator">&#x2032;</span><span class="math-row"><span class="math-brace">(</span><span class="math-identifier">x</span><span class="math-brace">)</span></span><span class="math-operator">=</span><span class="math-blank">&#x200D;</span><span class="math-underover"><span class="math-smaller"><span class="math-blank">&#x200D;</span></span><span class="math-operator">lim</span><span class="math-smaller"><span class="math-row"><span class="math-operator">&#x394;</span><span class="math-identifier">x</span><span class="math-operator">&#x2192;</span><span class="math-number">0</span></span></span></span><span class="math-blank">&#x200D;</span><span class="math-fraction"><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-identifier">f</span><span class="math-row"><span class="math-brace">(</span><span class="math-identifier">x</span><span class="math-operator">+</span><span class="math-operator">&#x394;</span><span class="math-identifier">x</span><span class="math-brace">)</span></span><span class="math-operator">&#x2212;</span><span class="math-identifier">f</span><span class="math-row"><span class="math-brace">(</span><span class="math-identifier">x</span><span class="math-brace">)</span></span></span></span></span></span></span><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-operator">&#x394;</span><span class="math-identifier">x</span></span></span></span></span></span></span></span>',
      :latex => 'f \' ( x ) = \\lim_{\\Delta x \\rightarrow 0} \\frac{f \\left ( x + \\Delta x \\right ) - f ( x )}{\\Delta x}',
  ))

  example('d/dx [x^n] = nx^(n - 1)', &should_generate(
      :ast => seq(
          infix('d', symbol('/'), symbol('dx')),
          paren(symbol('['), sup('x', 'n'), symbol(']')),
          symbol('='),
          'n',
          sup('x', grseq('n', symbol('-'), '1'))
      ),
      :mathml => '<math><mfrac><mi>d</mi><mi>dx</mi></mfrac><mrow><mo>[</mo><msup><mi>x</mi><mi>n</mi></msup><mo>]</mo></mrow><mo>=</mo><mi>n</mi><msup><mi>x</mi><mrow><mi>n</mi><mo>&#x2212;</mo><mn>1</mn></mrow></msup></math>',
      :html => '<span class="math-inline"><span class="math-blank">&#x200D;</span><span class="math-fraction"><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-identifier">d</span></span></span></span></span><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-identifier">dx</span></span></span></span></span></span><span class="math-row"><span class="math-brace">[</span><span class="math-identifier">x</span><span class="math-subsup"><span class="math-smaller"><span class="math-identifier">n</span></span><span class="math-smaller">&#x200D;</span></span><span class="math-brace">]</span></span><span class="math-operator">=</span><span class="math-identifier">n</span><span class="math-identifier">x</span><span class="math-subsup"><span class="math-smaller"><span class="math-row"><span class="math-identifier">n</span><span class="math-operator">&#x2212;</span><span class="math-number">1</span></span></span><span class="math-smaller">&#x200D;</span></span></span>',
      :latex => '\\frac{d}{dx} [ x^n ] = n x^{n - 1}',
  ))

  example('int_a^b f(x) dx = [F(x)]_a^b = F(b) - F(a)', &should_generate(
      :ast => seq(
          subsup(symbol('int'), 'a', 'b'),
          symbol('f'),
          paren('x'),
          symbol('dx'),
          symbol('='),
          subsup(paren(symbol('['), seq('F', paren('x')), symbol(']')), 'a', 'b'),
          symbol('='),
          'F', paren('b'),
          symbol('-'),
          'F', paren('a')
      ),
      :mathml => '<math><msubsup><mo>&#x222B;</mo><mi>a</mi><mi>b</mi></msubsup><mi>f</mi><mrow><mo>(</mo><mi>x</mi><mo>)</mo></mrow><mi>dx</mi><mo>=</mo><msubsup><mrow><mo>[</mo><mrow><mi>F</mi><mrow><mo>(</mo><mi>x</mi><mo>)</mo></mrow></mrow><mo>]</mo></mrow><mi>a</mi><mi>b</mi></msubsup><mo>=</mo><mi>F</mi><mrow><mo>(</mo><mi>b</mi><mo>)</mo></mrow><mo>&#x2212;</mo><mi>F</mi><mrow><mo>(</mo><mi>a</mi><mo>)</mo></mrow></math>',
      :html => '<span class="math-inline"><span class="math-operator">&#x222B;</span><span class="math-subsup"><span class="math-smaller"><span class="math-identifier">b</span></span><span class="math-smaller"><span class="math-identifier">a</span></span></span><span class="math-identifier">f</span><span class="math-row"><span class="math-brace">(</span><span class="math-identifier">x</span><span class="math-brace">)</span></span><span class="math-identifier">dx</span><span class="math-operator">=</span><span class="math-row"><span class="math-brace">[</span><span class="math-identifier">F</span><span class="math-row"><span class="math-brace">(</span><span class="math-identifier">x</span><span class="math-brace">)</span></span><span class="math-brace">]</span></span><span class="math-subsup"><span class="math-smaller"><span class="math-identifier">b</span></span><span class="math-smaller"><span class="math-identifier">a</span></span></span><span class="math-operator">=</span><span class="math-identifier">F</span><span class="math-row"><span class="math-brace">(</span><span class="math-identifier">b</span><span class="math-brace">)</span></span><span class="math-operator">&#x2212;</span><span class="math-identifier">F</span><span class="math-row"><span class="math-brace">(</span><span class="math-identifier">a</span><span class="math-brace">)</span></span></span>',
      :latex => '\\int_a^b f ( x ) dx = {\\left [ F ( x ) \\right ]}_a^b = F ( b ) - F ( a )',
  ))

  example('int_a^b f(x) dx = f(c)(b - a)', &should_generate(
      :ast => seq(
          subsup(symbol('int'), 'a', 'b'),
          symbol('f'),
          paren('x'),
          symbol('dx'),
          symbol('='),
          symbol('f'),
          paren('c'),
          paren(seq('b', symbol('-'), 'a')),
      ),
      :mathml => '<math><msubsup><mo>&#x222B;</mo><mi>a</mi><mi>b</mi></msubsup><mi>f</mi><mrow><mo>(</mo><mi>x</mi><mo>)</mo></mrow><mi>dx</mi><mo>=</mo><mi>f</mi><mrow><mo>(</mo><mi>c</mi><mo>)</mo></mrow><mrow><mo>(</mo><mrow><mi>b</mi><mo>&#x2212;</mo><mi>a</mi></mrow><mo>)</mo></mrow></math>',
      :html => '<span class="math-inline"><span class="math-operator">&#x222B;</span><span class="math-subsup"><span class="math-smaller"><span class="math-identifier">b</span></span><span class="math-smaller"><span class="math-identifier">a</span></span></span><span class="math-identifier">f</span><span class="math-row"><span class="math-brace">(</span><span class="math-identifier">x</span><span class="math-brace">)</span></span><span class="math-identifier">dx</span><span class="math-operator">=</span><span class="math-identifier">f</span><span class="math-row"><span class="math-brace">(</span><span class="math-identifier">c</span><span class="math-brace">)</span></span><span class="math-row"><span class="math-brace">(</span><span class="math-identifier">b</span><span class="math-operator">&#x2212;</span><span class="math-identifier">a</span><span class="math-brace">)</span></span></span>',
      :latex => '\\int_a^b f ( x ) dx = f ( c ) ( b - a )',
  ))

  example('ax^2 + bx + c = 0', &should_generate(
      :ast => seq(
          'a',
          sup('x', '2'),
          symbol('+'),
          'b',
          'x',
          symbol('+'),
          'c',
          symbol('='),
          '0'
      ),
      :mathml => '<math><mi>a</mi><msup><mi>x</mi><mn>2</mn></msup><mo>+</mo><mi>b</mi><mi>x</mi><mo>+</mo><mi>c</mi><mo>=</mo><mn>0</mn></math>',
      :html => '<span class="math-inline"><span class="math-identifier">a</span><span class="math-identifier">x</span><span class="math-subsup"><span class="math-smaller"><span class="math-number">2</span></span><span class="math-smaller">&#x200D;</span></span><span class="math-operator">+</span><span class="math-identifier">b</span><span class="math-identifier">x</span><span class="math-operator">+</span><span class="math-identifier">c</span><span class="math-operator">=</span><span class="math-number">0</span></span>',
      :latex => 'a x^2 + b x + c = 0',
  ))

  example('"average value"=1/(b-a) int_a^b f(x) dx', &should_generate(
      :ast => seq(
          'average value',
          symbol('='),
          infix('1', symbol('/'), grseq('b', symbol('-'), 'a')),
          subsup(symbol('int'), 'a', 'b'),
          symbol('f'),
          paren('x'),
          symbol('dx')
      ),
      :mathml => '<math><mtext>average value</mtext><mo>=</mo><mfrac><mn>1</mn><mrow><mi>b</mi><mo>&#x2212;</mo><mi>a</mi></mrow></mfrac><msubsup><mo>&#x222B;</mo><mi>a</mi><mi>b</mi></msubsup><mi>f</mi><mrow><mo>(</mo><mi>x</mi><mo>)</mo></mrow><mi>dx</mi></math>',
      :html => '<span class="math-inline"><span class="math-text">average value</span><span class="math-operator">=</span><span class="math-blank">&#x200D;</span><span class="math-fraction"><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-number">1</span></span></span></span></span><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-identifier">b</span><span class="math-operator">&#x2212;</span><span class="math-identifier">a</span></span></span></span></span></span></span><span class="math-operator">&#x222B;</span><span class="math-subsup"><span class="math-smaller"><span class="math-identifier">b</span></span><span class="math-smaller"><span class="math-identifier">a</span></span></span><span class="math-identifier">f</span><span class="math-row"><span class="math-brace">(</span><span class="math-identifier">x</span><span class="math-brace">)</span></span><span class="math-identifier">dx</span></span>',
      :latex => '\\text{average value} = \\frac{1}{b - a} \\int_a^b f ( x ) dx',
  ))

  example('d/dx[int_a^x f(t) dt] = f(x)', &should_generate(
      :ast => seq(
          infix('d', symbol('/'), symbol('dx')),
          paren(
              symbol('['),
              seq(subsup(symbol('int'), 'a', 'x'), symbol('f'), paren('t'), symbol('dt')),
              symbol(']')
          ),
          symbol('='),
          symbol('f'),
          paren('x'),
      ),
      :mathml => '<math><mfrac><mi>d</mi><mi>dx</mi></mfrac><mrow><mo>[</mo><mrow><msubsup><mo>&#x222B;</mo><mi>a</mi><mi>x</mi></msubsup><mi>f</mi><mrow><mo>(</mo><mi>t</mi><mo>)</mo></mrow><mi>dt</mi></mrow><mo>]</mo></mrow><mo>=</mo><mi>f</mi><mrow><mo>(</mo><mi>x</mi><mo>)</mo></mrow></math>',
      :html => '<span class="math-inline"><span class="math-blank">&#x200D;</span><span class="math-fraction"><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-identifier">d</span></span></span></span></span><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-identifier">dx</span></span></span></span></span></span><span class="math-row"><span class="math-brace">[</span><span class="math-operator">&#x222B;</span><span class="math-subsup"><span class="math-smaller"><span class="math-identifier">x</span></span><span class="math-smaller"><span class="math-identifier">a</span></span></span><span class="math-identifier">f</span><span class="math-row"><span class="math-brace">(</span><span class="math-identifier">t</span><span class="math-brace">)</span></span><span class="math-identifier">dt</span><span class="math-brace">]</span></span><span class="math-operator">=</span><span class="math-identifier">f</span><span class="math-row"><span class="math-brace">(</span><span class="math-identifier">x</span><span class="math-brace">)</span></span></span>',
      :latex => '\\frac{d}{dx} \\left [ \\int_a^x f ( t ) dt \\right ] = f ( x )',
  ))

  example('hat(ab) bar(xy) ul(A) vec(v)', &should_generate(
      :ast => seq(
          unary(symbol('hat'), grseq('a', 'b')),
          unary(symbol('bar'), grseq('x', 'y')),
          unary(symbol('ul'), group('A')),
          unary(symbol('vec'), group('v')),
      ),
      :mathml => '<math><mover accent="true"><mrow><mi>a</mi><mi>b</mi></mrow><mo>^</mo></mover><mover accent="true"><mrow><mi>x</mi><mi>y</mi></mrow><mo>&#xAF;</mo></mover><munder accentunder="true"><mi>A</mi><mo>_</mo></munder><mover accent="true"><mi>v</mi><mo>&#x2192;</mo></mover></math>',
      :html => '<span class="math-inline"><span class="math-blank">&#x200D;</span><span class="math-underover"><span class="math-smaller"><span class="math-operator">^</span></span><span class="math-row"><span class="math-identifier">a</span><span class="math-identifier">b</span></span><span class="math-smaller"><span class="math-blank">&#x200D;</span></span></span><span class="math-blank">&#x200D;</span><span class="math-underover"><span class="math-smaller"><span class="math-operator">&#xAF;</span></span><span class="math-row"><span class="math-identifier">x</span><span class="math-identifier">y</span></span><span class="math-smaller"><span class="math-blank">&#x200D;</span></span></span><span class="math-blank">&#x200D;</span><span class="math-underover"><span class="math-smaller"><span class="math-blank">&#x200D;</span></span><span class="math-identifier">A</span><span class="math-smaller"><span class="math-operator">_</span></span></span><span class="math-blank">&#x200D;</span><span class="math-underover"><span class="math-smaller"><span class="math-operator">&#x2192;</span></span><span class="math-identifier">v</span><span class="math-smaller"><span class="math-blank">&#x200D;</span></span></span></span>',
      :latex => '\\hat{a b} \\overline{x y} \\underline{A} \\vec{v}',
  ))

  example('z_12^34', &should_generate(
      :ast => subsup('z', '12', '34'),
      :mathml => '<math><msubsup><mi>z</mi><mn>12</mn><mn>34</mn></msubsup></math>',
      :html => '<span class="math-inline"><span class="math-identifier">z</span><span class="math-subsup"><span class="math-smaller"><span class="math-number">34</span></span><span class="math-smaller"><span class="math-number">12</span></span></span></span>',
      :latex => 'z_{12}^{34}',
  ))

  example('lim_(x->c)(f(x)-f(c))/(x-c)', &should_generate(
      :ast => seq(
          sub(symbol('lim'), grseq('x', symbol('->'), 'c')),
          infix(
              grseq(symbol('f'), paren('x'), symbol('-'), symbol('f'), paren('c')),
              symbol('/'),
              grseq('x', symbol('-'), 'c')
          )
      ),
      :mathml => '<math><munder><mo>lim</mo><mrow><mi>x</mi><mo>&#x2192;</mo><mi>c</mi></mrow></munder><mfrac><mrow><mi>f</mi><mrow><mo>(</mo><mi>x</mi><mo>)</mo></mrow><mo>&#x2212;</mo><mi>f</mi><mrow><mo>(</mo><mi>c</mi><mo>)</mo></mrow></mrow><mrow><mi>x</mi><mo>&#x2212;</mo><mi>c</mi></mrow></mfrac></math>',
      :html => '<span class="math-inline"><span class="math-blank">&#x200D;</span><span class="math-underover"><span class="math-smaller"><span class="math-blank">&#x200D;</span></span><span class="math-operator">lim</span><span class="math-smaller"><span class="math-row"><span class="math-identifier">x</span><span class="math-operator">&#x2192;</span><span class="math-identifier">c</span></span></span></span><span class="math-blank">&#x200D;</span><span class="math-fraction"><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-identifier">f</span><span class="math-row"><span class="math-brace">(</span><span class="math-identifier">x</span><span class="math-brace">)</span></span><span class="math-operator">&#x2212;</span><span class="math-identifier">f</span><span class="math-row"><span class="math-brace">(</span><span class="math-identifier">c</span><span class="math-brace">)</span></span></span></span></span></span></span><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-identifier">x</span><span class="math-operator">&#x2212;</span><span class="math-identifier">c</span></span></span></span></span></span></span></span>',
      :latex => '\\lim_{x \\rightarrow c} \\frac{f ( x ) - f ( c )}{x - c}',
  ))

  example('int_0^(pi/2) g(x) dx', &should_generate(
      :ast => seq(
          subsup(symbol('int'), '0', group(infix(symbol('pi'), symbol('/'), '2'))),
          symbol('g'), paren('x'),
          symbol('dx')
      ),
      :mathml => '<math><msubsup><mo>&#x222B;</mo><mn>0</mn><mfrac><mi>&#x3C0;</mi><mn>2</mn></mfrac></msubsup><mi>g</mi><mrow><mo>(</mo><mi>x</mi><mo>)</mo></mrow><mi>dx</mi></math>',
      :html => '<span class="math-inline"><span class="math-operator">&#x222B;</span><span class="math-subsup"><span class="math-smaller"><span class="math-blank">&#x200D;</span><span class="math-fraction"><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-identifier">&#x3C0;</span></span></span></span></span><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-number">2</span></span></span></span></span></span></span><span class="math-smaller"><span class="math-number">0</span></span></span><span class="math-identifier">g</span><span class="math-row"><span class="math-brace">(</span><span class="math-identifier">x</span><span class="math-brace">)</span></span><span class="math-identifier">dx</span></span>',
      :latex => '\\int_0^{\\frac{\\pi}{2}} g ( x ) dx',
  ))

  example('sum_(n=0)^oo a_n', &should_generate(
      :ast => seq(
          subsup(symbol('sum'), grseq('n', symbol('='), '0'), symbol('oo'),),
          sub('a', 'n')
      ),
      :mathml => '<math><munderover><mo>&#x2211;</mo><mrow><mi>n</mi><mo>=</mo><mn>0</mn></mrow><mo>&#x221E;</mo></munderover><msub><mi>a</mi><mi>n</mi></msub></math>',
      :html => '<span class="math-inline"><span class="math-blank">&#x200D;</span><span class="math-underover"><span class="math-smaller"><span class="math-operator">&#x221E;</span></span><span class="math-operator">&#x2211;</span><span class="math-smaller"><span class="math-row"><span class="math-identifier">n</span><span class="math-operator">=</span><span class="math-number">0</span></span></span></span><span class="math-identifier">a</span><span class="math-subsup"><span class="math-smaller">&#x200D;</span><span class="math-smaller"><span class="math-identifier">n</span></span></span></span>',
      :latex => '\\sum_{n = 0}^\\infty a_n',
  ))

  example('((1),(42))', &should_generate(
      :ast => matrix([%w[1], %w[42]]),
      :mathml => '<math><mrow><mo>(</mo><mtable><mtr><mtd><mn>1</mn></mtd></mtr><mtr><mtd><mn>42</mn></mtd></mtr></mtable><mo>)</mo></mrow></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-brace" style="font-size: 200%;">(</span><span class="math-matrix" style="grid-template-columns:repeat(1,1fr);grid-template-rows:repeat(2,1fr);"><span class="math-row"><span class="math-number">1</span></span><span class="math-row"><span class="math-number">42</span></span></span><span class="math-brace" style="font-size: 200%;">)</span></span></span>',
      :latex => '\\left ( \\begin{matrix} 1 \\\\ 42 \\end{matrix} \\right )',
  ))

  example('((1,2,3),(4,5,6),(7,8,9))', &should_generate(
      :ast => matrix([%w[1 2 3], %w[4 5 6], %w[7 8 9]]),
      :mathml => '<math><mrow><mo>(</mo><mtable><mtr><mtd><mn>1</mn></mtd><mtd><mn>2</mn></mtd><mtd><mn>3</mn></mtd></mtr><mtr><mtd><mn>4</mn></mtd><mtd><mn>5</mn></mtd><mtd><mn>6</mn></mtd></mtr><mtr><mtd><mn>7</mn></mtd><mtd><mn>8</mn></mtd><mtd><mn>9</mn></mtd></mtr></mtable><mo>)</mo></mrow></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-brace" style="font-size: 300%;">(</span><span class="math-matrix" style="grid-template-columns:repeat(3,1fr);grid-template-rows:repeat(3,1fr);"><span class="math-row"><span class="math-number">1</span></span><span class="math-row"><span class="math-number">2</span></span><span class="math-row"><span class="math-number">3</span></span><span class="math-row"><span class="math-number">4</span></span><span class="math-row"><span class="math-number">5</span></span><span class="math-row"><span class="math-number">6</span></span><span class="math-row"><span class="math-number">7</span></span><span class="math-row"><span class="math-number">8</span></span><span class="math-row"><span class="math-number">9</span></span></span><span class="math-brace" style="font-size: 300%;">)</span></span></span>',
      :latex => '\\left ( \\begin{matrix} 1 & 2 & 3 \\\\ 4 & 5 & 6 \\\\ 7 & 8 & 9 \\end{matrix} \\right )',
  ))

  example('|(a,b),(c,d)|=ad-bc', &should_generate(
      :ast => seq(
          matrix(symbol('|'), [%w(a b), %w(c d)], symbol('|'),),
          symbol('='),
          'a', 'd',
          symbol('-'),
          'b', 'c'
      ),
      :mathml => '<math><mrow><mo>|</mo><mtable><mtr><mtd><mi>a</mi></mtd><mtd><mi>b</mi></mtd></mtr><mtr><mtd><mi>c</mi></mtd><mtd><mi>d</mi></mtd></mtr></mtable><mo>|</mo></mrow><mo>=</mo><mi>a</mi><mi>d</mi><mo>&#x2212;</mo><mi>b</mi><mi>c</mi></math>',
      :mathml_word => '<math><mfenced open="|" close="|"><mtable><mtr><mtd><mi>a</mi></mtd><mtd><mi>b</mi></mtd></mtr><mtr><mtd><mi>c</mi></mtd><mtd><mi>d</mi></mtd></mtr></mtable></mfenced><mo>=</mo><mi>a</mi><mi>d</mi><mo>&#x2212;</mo><mi>b</mi><mi>c</mi></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-brace" style="font-size: 200%;">|</span><span class="math-matrix" style="grid-template-columns:repeat(2,1fr);grid-template-rows:repeat(2,1fr);"><span class="math-row"><span class="math-identifier">a</span></span><span class="math-row"><span class="math-identifier">b</span></span><span class="math-row"><span class="math-identifier">c</span></span><span class="math-row"><span class="math-identifier">d</span></span></span><span class="math-brace" style="font-size: 200%;">|</span></span><span class="math-operator">=</span><span class="math-identifier">a</span><span class="math-identifier">d</span><span class="math-operator">&#x2212;</span><span class="math-identifier">b</span><span class="math-identifier">c</span></span>',
      :latex => '\\left | \\begin{matrix} a & b \\\\ c & d \\end{matrix} \\right | = a d - b c',
  ))

  example('((a_(11), cdots , a_(1n)),(vdots, ddots, vdots),(a_(m1), cdots , a_(mn)))', &should_generate(
      :ast => matrix([
                         [sub('a', group('11')), symbol('cdots'), sub('a', grseq('1', 'n'))],
                         [symbol('vdots'), symbol('ddots'), symbol('vdots')],
                         [sub('a', grseq('m', '1')), symbol('cdots'), sub('a', grseq('m', 'n'))]
                     ]),
      :mathml => '<math><mrow><mo>(</mo><mtable><mtr><mtd><msub><mi>a</mi><mn>11</mn></msub></mtd><mtd><mo>&#x22EF;</mo></mtd><mtd><msub><mi>a</mi><mrow><mn>1</mn><mi>n</mi></mrow></msub></mtd></mtr><mtr><mtd><mo>&#x22EE;</mo></mtd><mtd><mo>&#x22F1;</mo></mtd><mtd><mo>&#x22EE;</mo></mtd></mtr><mtr><mtd><msub><mi>a</mi><mrow><mi>m</mi><mn>1</mn></mrow></msub></mtd><mtd><mo>&#x22EF;</mo></mtd><mtd><msub><mi>a</mi><mrow><mi>m</mi><mi>n</mi></mrow></msub></mtd></mtr></mtable><mo>)</mo></mrow></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-brace" style="font-size: 300%;">(</span><span class="math-matrix" style="grid-template-columns:repeat(3,1fr);grid-template-rows:repeat(3,1fr);"><span class="math-row"><span class="math-identifier">a</span><span class="math-subsup"><span class="math-smaller">&#x200D;</span><span class="math-smaller"><span class="math-number">11</span></span></span></span><span class="math-row"><span class="math-operator">&#x22EF;</span></span><span class="math-row"><span class="math-identifier">a</span><span class="math-subsup"><span class="math-smaller">&#x200D;</span><span class="math-smaller"><span class="math-row"><span class="math-number">1</span><span class="math-identifier">n</span></span></span></span></span><span class="math-row"><span class="math-operator">&#x22EE;</span></span><span class="math-row"><span class="math-operator">&#x22F1;</span></span><span class="math-row"><span class="math-operator">&#x22EE;</span></span><span class="math-row"><span class="math-identifier">a</span><span class="math-subsup"><span class="math-smaller">&#x200D;</span><span class="math-smaller"><span class="math-row"><span class="math-identifier">m</span><span class="math-number">1</span></span></span></span></span><span class="math-row"><span class="math-operator">&#x22EF;</span></span><span class="math-row"><span class="math-identifier">a</span><span class="math-subsup"><span class="math-smaller">&#x200D;</span><span class="math-smaller"><span class="math-row"><span class="math-identifier">m</span><span class="math-identifier">n</span></span></span></span></span></span><span class="math-brace" style="font-size: 300%;">)</span></span></span>',
      :latex => '\\left ( \\begin{matrix} a_{11} & \\cdots & a_{1 n} \\\\ \\vdots & \\ddots & \\vdots \\\\ a_{m 1} & \\cdots & a_{m n} \\end{matrix} \\right )',
  ))

  example('sum_(k=1)^n k = 1+2+ cdots +n=(n(n+1))/2', &should_generate(
      :ast => seq(
          subsup(symbol('sum'), grseq('k', symbol('='), '1'), 'n'),
          'k',
          symbol('='),
          '1', symbol('+'), '2', symbol('+'), symbol('cdots'), symbol('+'), 'n',
          symbol('='),
          infix(
              grseq('n', paren(seq('n', symbol('+'), '1'))),
              symbol('/'),
              '2'
          )
      ),
      :mathml => '<math><munderover><mo>&#x2211;</mo><mrow><mi>k</mi><mo>=</mo><mn>1</mn></mrow><mi>n</mi></munderover><mi>k</mi><mo>=</mo><mn>1</mn><mo>+</mo><mn>2</mn><mo>+</mo><mo>&#x22EF;</mo><mo>+</mo><mi>n</mi><mo>=</mo><mfrac><mrow><mi>n</mi><mrow><mo>(</mo><mrow><mi>n</mi><mo>+</mo><mn>1</mn></mrow><mo>)</mo></mrow></mrow><mn>2</mn></mfrac></math>',
      :html => '<span class="math-inline"><span class="math-blank">&#x200D;</span><span class="math-underover"><span class="math-smaller"><span class="math-identifier">n</span></span><span class="math-operator">&#x2211;</span><span class="math-smaller"><span class="math-row"><span class="math-identifier">k</span><span class="math-operator">=</span><span class="math-number">1</span></span></span></span><span class="math-identifier">k</span><span class="math-operator">=</span><span class="math-number">1</span><span class="math-operator">+</span><span class="math-number">2</span><span class="math-operator">+</span><span class="math-operator">&#x22EF;</span><span class="math-operator">+</span><span class="math-identifier">n</span><span class="math-operator">=</span><span class="math-blank">&#x200D;</span><span class="math-fraction"><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-identifier">n</span><span class="math-row"><span class="math-brace">(</span><span class="math-identifier">n</span><span class="math-operator">+</span><span class="math-number">1</span><span class="math-brace">)</span></span></span></span></span></span></span><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-number">2</span></span></span></span></span></span></span>',
      :latex => '\\sum_{k = 1}^n k = 1 + 2 + \\cdots + n = \\frac{n ( n + 1 )}{2}',
  ))

  example('"Скорость"=("Расстояние")/("Время")', &should_generate(
      :ast => seq(
          'Скорость',
          symbol('='),
          infix(group('Расстояние'), symbol('/'), group('Время'))
      ),
      :mathml => '<math><mtext>&#x421;&#x43A;&#x43E;&#x440;&#x43E;&#x441;&#x442;&#x44C;</mtext><mo>=</mo><mfrac><mtext>&#x420;&#x430;&#x441;&#x441;&#x442;&#x43E;&#x44F;&#x43D;&#x438;&#x435;</mtext><mtext>&#x412;&#x440;&#x435;&#x43C;&#x44F;</mtext></mfrac></math>',
      :html => '<span class="math-inline"><span class="math-text">&#x421;&#x43A;&#x43E;&#x440;&#x43E;&#x441;&#x442;&#x44C;</span><span class="math-operator">=</span><span class="math-blank">&#x200D;</span><span class="math-fraction"><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-text">&#x420;&#x430;&#x441;&#x441;&#x442;&#x43E;&#x44F;&#x43D;&#x438;&#x435;</span></span></span></span></span><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-text">&#x412;&#x440;&#x435;&#x43C;&#x44F;</span></span></span></span></span></span></span>',
      :latex => '\\text{Скорость} = \\frac{\\text{Расстояние}}{\\text{Время}}',
  ))

  example('bb (a + b) + cc c = fr (d^n)', &should_generate(
      :ast => seq(
          unary(symbol('bb'), grseq('a', symbol('+'), 'b')),
          symbol('+'),
          unary(symbol('cc'), 'c'),
          symbol('='),
          unary(symbol('fr'), group(sup('d', 'n')))
      ),
      :mathml => '<math><mstyle mathvariant="bold"><mrow><mi>a</mi><mo>+</mo><mi>b</mi></mrow></mstyle><mo>+</mo><mstyle mathvariant="script"><mi>c</mi></mstyle><mo>=</mo><mstyle mathvariant="fraktur"><msup><mi>d</mi><mi>n</mi></msup></mstyle></math>',
      :latex => '\\mathbf{a + b} + \\mathscr{c} = \\mathfrak{d^n}',
  ))

  example('max()', &should_generate(
      :ast => seq(symbol('max'), paren(nil)),
      :mathml => '<math><mo>max</mo><mrow><mo>(</mo><mo>)</mo></mrow></math>',
      :html => '<span class="math-inline"><span class="math-operator">max</span><span class="math-row"><span class="math-brace">(</span><span class="math-brace">)</span></span></span>',
      :latex => '\\max (  )',
  ))

  example('text("foo")', &should_generate(
      :ast => text('"foo"'),
      :mathml => '<math><mtext>"foo"</mtext></math>',
      :html => '<span class="math-inline"><span class="math-text">"foo"</span></span>',
      :latex => '\\text{"foo"}',
  ))

  example('ubrace(1 + 2) obrace(3 + 4', &should_generate(
      :ast => seq(
          unary(symbol('ubrace'), grseq('1', symbol('+'), '2')),
          unary(symbol('obrace'), group(symbol('('), seq('3', symbol('+'), '4'), nil))
      ),
      :mathml => '<math><munder accentunder="true"><mrow><mn>1</mn><mo>+</mo><mn>2</mn></mrow><mo>&#x23DF;</mo></munder><mover accent="true"><mrow><mn>3</mn><mo>+</mo><mn>4</mn></mrow><mo>&#x23DE;</mo></mover></math>',
      :latex => '\\underbrace{1 + 2} \\overbrace{3 + 4}',
  ))

  example('s\'_i = {(- 1, if s_i > s_(i + 1)),( + 1, if s_i <= s_(i + 1)):}', &should_generate(
      :ast => seq(
          's',
          sub(symbol('\''), 'i'),
          symbol('='),
          matrix(
              symbol('{'),
              [
                  [seq(symbol('-'), '1'), seq(symbol('if'), sub('s', 'i'), symbol('>'), sub('s', grseq('i', symbol('+'), '1')))],
                  [seq(symbol('+'), '1'), seq(symbol('if'), sub('s', 'i'), symbol('<='), sub('s', grseq('i', symbol('+'), '1')))]
              ],
              symbol(':}'),
          )
      ),
      :mathml => '<math><mi>s</mi><msub><mo>&#x2032;</mo><mi>i</mi></msub><mo>=</mo><mrow><mo>{</mo><mtable><mtr><mtd><mrow><mo>&#x2212;</mo><mn>1</mn></mrow></mtd><mtd><mrow><mo>if</mo><msub><mi>s</mi><mi>i</mi></msub><mo>&gt;</mo><msub><mi>s</mi><mrow><mi>i</mi><mo>+</mo><mn>1</mn></mrow></msub></mrow></mtd></mtr><mtr><mtd><mrow><mo>+</mo><mn>1</mn></mrow></mtd><mtd><mrow><mo>if</mo><msub><mi>s</mi><mi>i</mi></msub><mo>&#x2264;</mo><msub><mi>s</mi><mrow><mi>i</mi><mo>+</mo><mn>1</mn></mrow></msub></mrow></mtd></mtr></mtable></mrow></math>',
      :latex => 's \'_i = \\left \\{ \\begin{matrix} - 1 & \\operatorname{if} s_i > s_{i + 1} \\\\ + 1 & \\operatorname{if} s_i \\le s_{i + 1} \\end{matrix} \\right .',
  ))

  example('s\'_i = {(, if s_i > s_(i + 1)),( + 1,):}', &should_generate(
      :ast => seq(
          's',
          sub(symbol('\''), 'i'),
          symbol('='),
          matrix(
              symbol('{'),
              [
                  [[], [symbol('if'), sub('s', 'i'), symbol('>'), sub('s', grseq('i', symbol('+'), '1'))]],
                  [[symbol('+'), '1'], []]
              ],
              symbol(':}')
          )
      ),
      :mathml => '<math><mi>s</mi><msub><mo>&#x2032;</mo><mi>i</mi></msub><mo>=</mo><mrow><mo>{</mo><mtable><mtr><mtd></mtd><mtd><mrow><mo>if</mo><msub><mi>s</mi><mi>i</mi></msub><mo>&gt;</mo><msub><mi>s</mi><mrow><mi>i</mi><mo>+</mo><mn>1</mn></mrow></msub></mrow></mtd></mtr><mtr><mtd><mrow><mo>+</mo><mn>1</mn></mrow></mtd><mtd></mtd></mtr></mtable></mrow></math>',
      :latex => 's \'_i = \\left \\{ \\begin{matrix}  & \\operatorname{if} s_i > s_{i + 1} \\\\ + 1 &  \\end{matrix} \\right .',
  ))

  example('{:(a,b),(c,d):}', &should_generate(
      :ast => matrix(
          symbol('{:'),
          [%w(a b), %w(c d)],
          symbol(':}')
      ),
      :mathml => '<math><mtable><mtr><mtd><mi>a</mi></mtd><mtd><mi>b</mi></mtd></mtr><mtr><mtd><mi>c</mi></mtd><mtd><mi>d</mi></mtd></mtr></mtable></math>',
      :latex => '\\begin{matrix} a & b \\\\ c & d \\end{matrix}',
  ))

  example('overset (a + b) (c + d)', &should_generate(
      :ast => binary(
          symbol('overset'),
          grseq('a', symbol('+'), 'b'),
          grseq('c', symbol('+'), 'd')
      ),
      :mathml => '<math><mover><mrow><mi>c</mi><mo>+</mo><mi>d</mi></mrow><mrow><mi>a</mi><mo>+</mo><mi>b</mi></mrow></mover></math>',
      :html => '<span class="math-inline"><span class="math-blank">&#x200D;</span><span class="math-underover"><span class="math-smaller"><span class="math-row"><span class="math-identifier">a</span><span class="math-operator">+</span><span class="math-identifier">b</span></span></span><span class="math-row"><span class="math-identifier">c</span><span class="math-operator">+</span><span class="math-identifier">d</span></span><span class="math-smaller"><span class="math-blank">&#x200D;</span></span></span></span>',
      :latex => '\\overset{a + b}{c + d}',
  ))

  example('underset a b', &should_generate(
      :ast => binary(
          symbol('underset'),
          'a',
          'b'
      ),
      :mathml => '<math><munder><mi>b</mi><mi>a</mi></munder></math>',
      :html => '<span class="math-inline"><span class="math-blank">&#x200D;</span><span class="math-underover"><span class="math-smaller"><span class="math-blank">&#x200D;</span></span><span class="math-identifier">b</span><span class="math-smaller"><span class="math-identifier">a</span></span></span></span>',
      :latex => '\\underset{a}{b}',
  ))

  example('sin a_c^b', &should_generate(
      :ast => seq(
          symbol('sin'),
          subsup('a', 'c', 'b')
      ),
      :mathml => '<math><mi>sin</mi><msubsup><mi>a</mi><mi>c</mi><mi>b</mi></msubsup></math>',
      :html => '<span class="math-inline"><span class="math-identifier">sin</span><span class="math-identifier">a</span><span class="math-subsup"><span class="math-smaller"><span class="math-identifier">b</span></span><span class="math-smaller"><span class="math-identifier">c</span></span></span></span>',
      :latex => '\\sin a_c^b',
  ))

  example('max a_c^b', &should_generate(
      :ast => seq(
          symbol('max'),
          subsup('a', 'c', 'b')
      ),
      :mathml => '<math><mo>max</mo><msubsup><mi>a</mi><mi>c</mi><mi>b</mi></msubsup></math>',
      :html => '<span class="math-inline"><span class="math-operator">max</span><span class="math-identifier">a</span><span class="math-subsup"><span class="math-smaller"><span class="math-identifier">b</span></span><span class="math-smaller"><span class="math-identifier">c</span></span></span></span>',
      :latex => '\\max a_c^b',
  ))

  example('norm a_c^b', &should_generate(
      :ast => subsup(unary(symbol('norm'), 'a'), 'c', 'b'),
      :mathml => '<math><msubsup><mrow><mo>&#x2225;</mo><mi>a</mi><mo>&#x2225;</mo></mrow><mi>c</mi><mi>b</mi></msubsup></math>',
      :html => '<span class="math-inline"><span class="math-row"><span class="math-brace">&#x2225;</span><span class="math-identifier">a</span><span class="math-brace">&#x2225;</span></span><span class="math-subsup"><span class="math-smaller"><span class="math-identifier">b</span></span><span class="math-smaller"><span class="math-identifier">c</span></span></span></span>',
      :latex => '{\\lVert a \\rVert}_c^b',
  ))

  example('overarc a_b^c', &should_generate(
      :ast => subsup(unary(symbol('overarc'), 'a'), 'b', 'c'),
      :mathml => '<math><msubsup><mover accent="true"><mi>a</mi><mo>&#x23DC;</mo></mover><mi>b</mi><mi>c</mi></msubsup></math>',
      :latex => '{\\overset{\\frown}{a}}_b^c'
  ))

  example('frown a_b^c', &should_generate(
      :ast => seq(symbol('frown'), subsup('a', 'b', 'c')),
      :mathml => '<math><mo>&#x2322;</mo><msubsup><mi>a</mi><mi>b</mi><mi>c</mi></msubsup></math>',
      :latex => '\\frown a_b^c',
  ))

  example('sin(a_c^b)', &should_generate(
      :ast => seq(symbol('sin'), paren(subsup('a', 'c', 'b'))),
      :mathml => '<math><mi>sin</mi><mrow><mo>(</mo><msubsup><mi>a</mi><mi>c</mi><mi>b</mi></msubsup><mo>)</mo></mrow></math>',
      :latex => '\\sin ( a_c^b )',
  ))

  example('text(a)a2)', &should_generate(
      :ast => seq(text('a'), identifier('a'), number('2'), symbol(')')),
      :mathml => '<math><mtext>a</mtext><mi>a</mi><mn>2</mn><mo>)</mo></math>',
      :html => '<span class="math-inline"><span class="math-text">a</span><span class="math-identifier">a</span><span class="math-number">2</span><span class="math-operator">)</span></span>',
      :latex => '\\text{a} a 2 )',
  ))

  example('cancel(a_b^c) cancel a_b^c', &should_generate(
      :ast => seq(
          unary(symbol('cancel'), group(subsup('a', 'b', 'c'))),
          subsup(unary(symbol('cancel'), 'a'), 'b', 'c')
      ),
      :mathml => '<math><menclose notation="updiagonalstrike"><msubsup><mi>a</mi><mi>b</mi><mi>c</mi></msubsup></menclose><msubsup><menclose notation="updiagonalstrike"><mi>a</mi></menclose><mi>b</mi><mi>c</mi></msubsup></math>',
      :latex => '\\cancel{a_b^c} {\\cancel{a}}_b^c',
  ))

  example('color(red)(x) color(#123)(y) color(#1234ab)(z) colortext(blue)(a_b^c)', &should_generate(
      :ast => seq(
          binary(symbol('color'), color(255, 0, 0, 'red'), group('x')),
          binary(symbol('color'), color(17, 34, 51, '#123'), group('y')),
          binary(symbol('color'), color(18, 52, 171, '#1234ab'), group('z')),
          binary(symbol('color'), color(0, 0, 255, 'blue'), group(subsup('a', 'b', 'c')))
      ),
      :mathml => '<math><mstyle mathcolor="#ff0000"><mi>x</mi></mstyle><mstyle mathcolor="#112233"><mi>y</mi></mstyle><mstyle mathcolor="#1234ab"><mi>z</mi></mstyle><mstyle mathcolor="#0000ff"><msubsup><mi>a</mi><mi>b</mi><mi>c</mi></msubsup></mstyle></math>',
      :latex => '{\\color{red} x} {\\color[RGB]{17,34,51} y} {\\color[RGB]{18,52,171} z} {\\color{blue} a_b^c}',
  ))

  example('{ x\ : \ x in A ^^ x in B }', &should_generate(
      :ast => paren(
          symbol('{'),
          seq('x', symbol('\ '), ':', symbol('\ '), 'x', symbol('in'), 'A', symbol('^^'), 'x', symbol('in'), 'B'),
          symbol('}')
      ),
      :mathml => '<math><mrow><mo>{</mo><mrow><mi>x</mi><mo>&#xA0;</mo><mi>:</mi><mo>&#xA0;</mo><mi>x</mi><mo>&#x2208;</mo><mi>A</mi><mo>&#x2227;</mo><mi>x</mi><mo>&#x2208;</mo><mi>B</mi></mrow><mo>}</mo></mrow></math>',
      :latex => '\\left \\{ x \\; : \\; x \\in A \\wedge x \\in B \\right \\}',
  ))

  example('ii', &should_generate(
      :ast => unary(symbol('ii'), identifier('')),
      :mathml => '<math><mstyle mathvariant="italic"><mi></mi></mstyle></math>'
  ))

  example('hat', &should_generate(
      :ast => unary(symbol('hat'), identifier('')),
      :mathml => '<math><mover><mi></mi><mo>^</mo></mover></math>'
  ))

  version = RUBY_VERSION.split('.').map { |s| s.to_i }

  if version[0] > 1 || version[1] > 8
    example('Скорость=(Расстояние)/(Время)', &should_generate(
        :ast => seq(
            'С', 'к', 'о', 'р', 'о', 'с', 'т', 'ь',
            symbol('='),
            infix(
                grseq('Р', 'а', 'с', 'с', 'т', 'о', 'я', 'н', 'и', 'е'),
                symbol('/'),
                grseq('В', 'р', 'е', 'м', 'я')
            )
        ),
        :mathml => '<math><mi>&#x421;</mi><mi>&#x43A;</mi><mi>&#x43E;</mi><mi>&#x440;</mi><mi>&#x43E;</mi><mi>&#x441;</mi><mi>&#x442;</mi><mi>&#x44C;</mi><mo>=</mo><mfrac><mrow><mi>&#x420;</mi><mi>&#x430;</mi><mi>&#x441;</mi><mi>&#x441;</mi><mi>&#x442;</mi><mi>&#x43E;</mi><mi>&#x44F;</mi><mi>&#x43D;</mi><mi>&#x438;</mi><mi>&#x435;</mi></mrow><mrow><mi>&#x412;</mi><mi>&#x440;</mi><mi>&#x435;</mi><mi>&#x43C;</mi><mi>&#x44F;</mi></mrow></mfrac></math>',
        :html => '<span class="math-inline"><span class="math-identifier">&#x421;</span><span class="math-identifier">&#x43A;</span><span class="math-identifier">&#x43E;</span><span class="math-identifier">&#x440;</span><span class="math-identifier">&#x43E;</span><span class="math-identifier">&#x441;</span><span class="math-identifier">&#x442;</span><span class="math-identifier">&#x44C;</span><span class="math-operator">=</span><span class="math-blank">&#x200D;</span><span class="math-fraction"><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-identifier">&#x420;</span><span class="math-identifier">&#x430;</span><span class="math-identifier">&#x441;</span><span class="math-identifier">&#x441;</span><span class="math-identifier">&#x442;</span><span class="math-identifier">&#x43E;</span><span class="math-identifier">&#x44F;</span><span class="math-identifier">&#x43D;</span><span class="math-identifier">&#x438;</span><span class="math-identifier">&#x435;</span></span></span></span></span></span><span class="math-fraction_row"><span class="math-fraction_cell"><span class="math-smaller"><span class="math-row"><span class="math-row"><span class="math-identifier">&#x412;</span><span class="math-identifier">&#x440;</span><span class="math-identifier">&#x435;</span><span class="math-identifier">&#x43C;</span><span class="math-identifier">&#x44F;</span></span></span></span></span></span></span></span>',
        :latex => 'С к о р о с т ь = \\frac{Р а с с т о я н и е}{В р е м я}'
    ))
  end
end

describe 'AsciiMath::Parser', :variant => :ast do
  include_examples 'AsciiMath Examples'
end

describe 'AsciiMath::MathMLBuilder', :variant => :mathml do
  include_examples 'AsciiMath Examples'
end

describe 'AsciiMath::MathMLBuilder Microsoft Office', :variant => :mathml_word do
  include_examples 'AsciiMath Examples'
end

describe 'AsciiMath::HTMLBuilder', :variant => :html do
  include_examples 'AsciiMath Examples', :html
end

describe 'AsciiMath::LatexBuilder', :variant => :latex do
  include_examples 'AsciiMath Examples'
end
