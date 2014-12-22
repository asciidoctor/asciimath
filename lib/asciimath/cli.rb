require_relative 'parser'
require_relative 'mathml'

module AsciiMath
  module CLI
    def self.run(args)
      asciimath = args.last
      mathml = AsciiMath.parse(asciimath).to_mathml
      puts mathml
    end
  end
end