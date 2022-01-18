module AsciiMath
  class ColorTableBuilder
    def initialize()
      @table = {}
    end

    def add(*names, r, g, b)
      entry = {
          :r => r,
          :g => g,
          :b => b
      }.freeze

      names.each { |name| @table[name.freeze] = entry }
    end

    def build
      @table.dup.freeze
    end
  end
end