require_relative 'parser'
require_relative 'mathml'
require_relative 'html'
require_relative 'latex'

module AsciiMath
  module CLI
    def self.run(args)
      asciimath = args.last
      output = ''
      if args.length == 1 || args.first == "mathml"
        output = AsciiMath.parse(asciimath).to_mathml
      elsif args.first == "html"
        output = AsciiMath.parse(asciimath).to_html
      elsif args.first == "latex"
        output = AsciiMath.parse(asciimath).to_latex
      end
      puts output
    end
  end
end
