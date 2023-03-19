module AsciiMath
  class SymbolTableBuilder
    def initialize(allow_symbol_overwrites: true)
      @table = {}
      @allow_symbol_overwrites = allow_symbol_overwrites
    end

    def add(*args)
      raise 'Insufficient arguments' if args.length < 3

      entry = {}
      if args.last.is_a?(Hash)
        entry.merge!(args.pop)
      end
      entry[:type] = args.pop
      entry[:value] = args.pop

      entry.freeze
      args.map(&:freeze).each do |name|
        raise "Symbol overwrites are disallowed, but were attempted for #{name}" if !@allow_symbol_overwrites && !@table[name].nil?

        @table[name] = entry
      end
    end

    def build
      @table.dup.freeze
    end
  end
end