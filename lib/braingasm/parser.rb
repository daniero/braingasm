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
        when '>'
          @program.push right
        when '<'
          @program.push left
        when '+'
          @program.push inc
        when '-'
          @program.push dec
        when '.'
          @program.push @@print
        end
      end
      @program
    end

    # Nullary instructions:

    @@dump = -> m { m.inst_print_tape }
    @@print = -> m { m.inst_print_cell }

    # Instructions taking parameters

    def right(n=1)
      -> m { m.inst_right(n) }
    end

    def left(n=1)
      -> m { m.inst_left(n) }
    end

    def inc(n=1)
      -> m { m.inst_inc(n) }
    end

    def dec(n=1)
      -> m { m.inst_dec(n) }
    end

  end
end
