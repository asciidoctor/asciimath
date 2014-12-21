require_relative 'parser'
require_relative 'mathml'

module Asciimath
  module CLI
    def self.run(args)
      asciimath = args.last
      mathml = Asciimath.parse(asciimath).to_mathml
      puts mathml
    end
  end
end