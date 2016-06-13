module Braingasm

  # Takes some input code and generates the program
  class Parser
    def initialize(input)
      @input = input
      @program = []
    end

    def parse
      # TODO actally parse @input
      @program.push inc(5)
      @program.push @@dump
      @program.push dec(3)
      @program.push @@dump
      @program
    end

    # Nullary instructions:

    @@dump = -> m { m.inst_print_tape }

    # Instructions taking parameters

    def inc(n)
      -> m { m.inst_inc(n) }
    end

    def dec(n)
      -> m { m.inst_dec(n) }
    end

  end
end
