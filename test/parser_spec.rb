require 'rspec'
require 'asciimath'

TEST_CASES = {
    'x+b/(2a)<+-sqrt((b^2)/(4a^2)-c/a)' =>
        '<math><mi>x</mi><mo>+</mo><mfrac><mi>b</mi><mrow><mn>2</mn><mi>a</mi></mrow></mfrac><mo>&#x003C;</mo><mo>&#x00B1;</mo><msqrt><mrow><mfrac><msup><mi>b</mi><mn>2</mn></msup><mrow><mn>4</mn><msup><mi>a</mi><mn>2</mn></msup></mrow></mfrac><mo>&#x2212;</mo><mfrac><mi>c</mi><mi>a</mi></mfrac></mrow></msqrt></math>',
    'a^2 + b^2 = c^2' =>
        '<math><msup><mi>a</mi><mn>2</mn></msup><mo>+</mo><msup><mi>b</mi><mn>2</mn></msup><mo>=</mo><msup><mi>c</mi><mn>2</mn></msup></math>',
    'x = (-b+-sqrt(b^2-4ac))/(2a)' =>
        '<math><mi>x</mi><mo>=</mo><mfrac><mrow><mo>&#x2212;</mo><mi>b</mi><mo>&#x00B1;</mo><msqrt><mrow><msup><mi>b</mi><mn>2</mn></msup><mn>-4</mn><mi>a</mi><mi>c</mi></mrow></msqrt></mrow><mrow><mn>2</mn><mi>a</mi></mrow></mfrac></math>',
    'm = (y_2 - y_1)/(x_2 - x_1) = (Deltay)/(Deltax)' =>
        '<math><mi>m</mi><mo>=</mo><mfrac><mrow><msub><mi>y</mi><mn>2</mn></msub><mo>&#x2212;</mo><msub><mi>y</mi><mn>1</mn></msub></mrow><mrow><msub><mi>x</mi><mn>2</mn></msub><mo>&#x2212;</mo><msub><mi>x</mi><mn>1</mn></msub></mrow></mfrac><mo>=</mo><mfrac><mrow><mo>&#x0394;</mo><mi>y</mi></mrow><mrow><mo>&#x0394;</mo><mi>x</mi></mrow></mfrac></math>',
    'f\'(x) = lim_(Deltax->0)(f(x+Deltax)-f(x))/(Deltax)' =>
        '<math><mi>f</mi><mi>\'</mi><mrow><mo>(</mo><mi>x</mi><mo>)</mo></mrow><mo>=</mo><munder><mo>lim</mo><mrow><mo>&#x0394;</mo><mi>x</mi><mo>&#x2192;</mo><mn>0</mn></mrow></munder><mfrac><mrow><mi>f</mi><mrow><mo>(</mo><mi>x</mi><mo>+</mo><mo>&#x0394;</mo><mi>x</mi><mo>)</mo></mrow><mo>&#x2212;</mo><mi>f</mi><mrow><mo>(</mo><mi>x</mi><mo>)</mo></mrow></mrow><mrow><mo>&#x0394;</mo><mi>x</mi></mrow></mfrac></math>',
    'd/dx [x^n] = nx^(n - 1)' =>
        '<math><mfrac><mi>d</mi><mi>dx</mi></mfrac><mrow><mo>[</mo><msup><mi>x</mi><mi>n</mi></msup><mo>]</mo></mrow><mo>=</mo><mi>n</mi><msup><mi>x</mi><mrow><mi>n</mi><mo>&#x2212;</mo><mn>1</mn></mrow></msup></math>',
    'int_a^b f(x) dx = [F(x)]_a^b = F(b) - F(a)' =>
        '<math><msubsup><mo>&#x222B;</mo><mi>a</mi><mi>b</mi></msubsup><mi>f</mi><mrow><mo>(</mo><mi>x</mi><mo>)</mo></mrow><mi>dx</mi><mo>=</mo><msubsup><mrow><mo>[</mo><mi>F</mi><mrow><mo>(</mo><mi>x</mi><mo>)</mo></mrow><mo>]</mo></mrow><mi>a</mi><mi>b</mi></msubsup><mo>=</mo><mi>F</mi><mrow><mo>(</mo><mi>b</mi><mo>)</mo></mrow><mo>&#x2212;</mo><mi>F</mi><mrow><mo>(</mo><mi>a</mi><mo>)</mo></mrow></math>',
    'int_a^b f(x) dx = f(c)(b - a)' =>
        '<math><msubsup><mo>&#x222B;</mo><mi>a</mi><mi>b</mi></msubsup><mi>f</mi><mrow><mo>(</mo><mi>x</mi><mo>)</mo></mrow><mi>dx</mi><mo>=</mo><mi>f</mi><mrow><mo>(</mo><mi>c</mi><mo>)</mo></mrow><mrow><mo>(</mo><mi>b</mi><mo>&#x2212;</mo><mi>a</mi><mo>)</mo></mrow></math>',
    'ax^2 + bx + c = 0' =>
        '<math><mi>a</mi><msup><mi>x</mi><mn>2</mn></msup><mo>+</mo><mi>b</mi><mi>x</mi><mo>+</mo><mi>c</mi><mo>=</mo><mn>0</mn></math>',
    '"average value"=1/(b-a) int_a^b f(x) dx' =>
        '<math><mtext>average value</mtext><mo>=</mo><mfrac><mn>1</mn><mrow><mi>b</mi><mo>&#x2212;</mo><mi>a</mi></mrow></mfrac><msubsup><mo>&#x222B;</mo><mi>a</mi><mi>b</mi></msubsup><mi>f</mi><mrow><mo>(</mo><mi>x</mi><mo>)</mo></mrow><mi>dx</mi></math>',
    'd/dx[int_a^x f(t) dt] = f(x)' =>
        '<math><mfrac><mi>d</mi><mi>dx</mi></mfrac><mrow><mo>[</mo><msubsup><mo>&#x222B;</mo><mi>a</mi><mi>x</mi></msubsup><mi>f</mi><mrow><mo>(</mo><mi>t</mi><mo>)</mo></mrow><mi>dt</mi><mo>]</mo></mrow><mo>=</mo><mi>f</mi><mrow><mo>(</mo><mi>x</mi><mo>)</mo></mrow></math>',
    'hat(ab) bar(xy) ul(A) vec(v)' =>
        '<math><mover><mrow><mi>a</mi><mi>b</mi></mrow><mo>&#x005E;</mo></mover><mover><mrow><mi>x</mi><mi>y</mi></mrow><mo>&#x00AF;</mo></mover><munder><mi>A</mi><mo>_</mo></munder><mover><mi>v</mi><mo>&#x2192;</mo></mover></math>',
    'z_12^34' =>
        '<math><msubsup><mi>z</mi><mn>12</mn><mn>34</mn></msubsup></math>',
    'lim_(x->c)(f(x)-f(c))/(x-c)' =>
        '<math><munder><mo>lim</mo><mrow><mi>x</mi><mo>&#x2192;</mo><mi>c</mi></mrow></munder><mfrac><mrow><mi>f</mi><mrow><mo>(</mo><mi>x</mi><mo>)</mo></mrow><mo>&#x2212;</mo><mi>f</mi><mrow><mo>(</mo><mi>c</mi><mo>)</mo></mrow></mrow><mrow><mi>x</mi><mo>&#x2212;</mo><mi>c</mi></mrow></mfrac></math>',
    'int_0^(pi/2) g(x) dx' =>
        '<math><msubsup><mo>&#x222B;</mo><mn>0</mn><mfrac><mi>&#x03c0;</mi><mn>2</mn></mfrac></msubsup><mi>g</mi><mrow><mo>(</mo><mi>x</mi><mo>)</mo></mrow><mi>dx</mi></math>',
    'sum_(n=0)^oo a_n' =>
        '<math><munderover><mo>&#x2211;</mo><mrow><mi>n</mi><mo>=</mo><mn>0</mn></mrow><mo>&#x221E;</mo></munderover><msub><mi>a</mi><mi>n</mi></msub></math>',
    '((1,2,3),(4,5,6),(7,8,9))' =>
        '<math><mrow><mo>(</mo><mtable><mtr><mtd><mn>1</mn></mtd><mtd><mn>2</mn></mtd><mtd><mn>3</mn></mtd></mtr><mtr><mtd><mn>4</mn></mtd><mtd><mn>5</mn></mtd><mtd><mn>6</mn></mtd></mtr><mtr><mtd><mn>7</mn></mtd><mtd><mn>8</mn></mtd><mtd><mn>9</mn></mtd></mtr></mtable><mo>)</mo></mrow></math>',
    '|(a,b),(c,d)|=ad-bc' =>
        '<math><mrow><mo>|</mo><mtable><mtr><mtd><mi>a</mi></mtd><mtd><mi>b</mi></mtd></mtr><mtr><mtd><mi>c</mi></mtd><mtd><mi>d</mi></mtd></mtr></mtable><mo>|</mo></mrow><mo>=</mo><mi>a</mi><mi>d</mi><mo>&#x2212;</mo><mi>b</mi><mi>c</mi></math>',
    '((a_(11), cdots , a_(1n)),(vdots, ddots, vdots),(a_(m1), cdots , a_(mn)))' =>
        '<math><mrow><mo>(</mo><mtable><mtr><mtd><msub><mi>a</mi><mn>11</mn></msub></mtd><mtd><mo>&#x22EF;</mo></mtd><mtd><msub><mi>a</mi><mrow><mn>1</mn><mi>n</mi></mrow></msub></mtd></mtr><mtr><mtd><mo>&#x22EE;</mo></mtd><mtd><mo>&#x22F1;</mo></mtd><mtd><mo>&#x22EE;</mo></mtd></mtr><mtr><mtd><msub><mi>a</mi><mrow><mi>m</mi><mn>1</mn></mrow></msub></mtd><mtd><mo>&#x22EF;</mo></mtd><mtd><msub><mi>a</mi><mrow><mi>m</mi><mi>n</mi></mrow></msub></mtd></mtr></mtable><mo>)</mo></mrow></math>',
    'sum_(k=1)^n k = 1+2+ cdots +n=(n(n+1))/2' =>
        '<math><munderover><mo>&#x2211;</mo><mrow><mi>k</mi><mo>=</mo><mn>1</mn></mrow><mi>n</mi></munderover><mi>k</mi><mo>=</mo><mn>1</mn><mo>+</mo><mn>2</mn><mo>+</mo><mo>&#x22EF;</mo><mo>+</mo><mi>n</mi><mo>=</mo><mfrac><mrow><mi>n</mi><mrow><mo>(</mo><mi>n</mi><mo>+</mo><mn>1</mn><mo>)</mo></mrow></mrow><mn>2</mn></mfrac></math>',
}

module AsciimathHelper
  def expect_mathml(asciimath, mathml)
    expect(Asciimath.parse(asciimath).to_mathml).to eq(mathml)
  end
end

RSpec.configure do |c|
  c.include AsciimathHelper
end

describe "Asciimath::MathMLBuilder" do
  TEST_CASES.each_pair do |asciimath, mathml|
    it "should produce identical output to asciimathml.js for '#{asciimath}'" do
      expect_mathml(asciimath, mathml)
    end
  end

  it 'should not generate mo elements for {: and :}' do
    expect_mathml '{:(a,b),(c,d):}', '<math><mrow><mtable><mtr><mtd><mi>a</mi></mtd><mtd><mi>b</mi></mtd></mtr><mtr><mtd><mi>c</mi></mtd><mtd><mi>d</mi></mtd></mtr></mtable></mrow></math>'
  end
end