module Braingasm

  # Takes some input code and generates the program
  class Parser
    def initialize(input)
      @input = input
      @program = []
    end

    def parse
      # TODO actally parse @input
      @program.push @@dump
      @program.push inc(5)
      @program.push @@dump
      @program
    end

    # Nullary instructions:

    @@dump = -> m { m.print_tape }

    # Instructions taking parameters

    def inc(n)
      -> m { m.inc(n) }
    end

  end
end
