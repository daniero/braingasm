module Braingasm

  # Takes some input code and generates the program
  class Parser
    def initialize(input)
      @input = input
      @program = []
    end

    def parse
      tokens = @input.chars

      tokens.each do |token|
        case token
        when '+'
          @program.push inc
        when '-'
          @program.push dec
        end
      end
      @program.push @@dump
    end

    # Nullary instructions:

    @@dump = -> m { m.inst_print_tape }

    # Instructions taking parameters

    def inc(n=1)
      -> m { m.inst_inc(n) }
    end

    def dec(n=1)
      -> m { m.inst_dec(n) }
    end

  end
end
