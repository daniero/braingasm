module Braingasm
  class BraingasmError < RuntimeError
    def type
      self.class.to_s
    end
  end

  class ParsingError < BraingasmError
    attr_reader :line, :column
    def initialize(line=nil, column=nil)
      @line = line
      @column = column
    end

    def type
      "#{super} [line #@line, col #@column]"
    end
  end

  class VMError < BraingasmError
  end

  class JumpSignal < VMError
    attr_reader :to
    def initialize(to)
      @to = to
    end
  end
end
