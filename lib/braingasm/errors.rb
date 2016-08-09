module Braingasm
  class ParsingError < RuntimeError
    def initialize(input = nil)
      @line = input.line if input
      @column = input.column if input
    end

    def type
      "#{super} [line #@line, col #@column]"
    end
  end

  class VMError < RuntimeError
  end
end
