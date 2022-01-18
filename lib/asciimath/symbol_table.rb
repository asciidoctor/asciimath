module AsciiMath
  class SymbolTableBuilder
    def initialize()
      @table = {}
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
      args.each { |name| @table[name.freeze] = entry }
    end

    def build
      @table.dup.freeze
    end
  end
end