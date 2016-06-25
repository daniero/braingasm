module Braingasm

  # Takes some input code and generates the program
  class Parser
    def initialize(input)
      @input = input
      @program = []
      @loop_stack = []
    end

    def parse
      tokens = @input.scan(/\S/)

      tokens.each_with_index do |token, index|
        case token
        when '>'
          @program.push right()
        when '<'
          @program.push left()
        when '+'
          @program.push inc()
        when '-'
          @program.push dec()
        when '.'
          @program.push print()
        when ','
          @program.push read()
        when '['
          new_loop = Loop.new
          new_loop.start_index = index
          @program.push new_loop
          @loop_stack.push new_loop
        when ']'
          current_loop = @loop_stack.pop
          current_loop.stop_index = index
          @program.push jump(current_loop.start_index)
        end
      end
      @program
    end

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

    def print()
      -> m { m.inst_print_cell }
    end

    def read()
      -> m { m.inst_read_byte }
    end

    def jump(to)
      -> m { m.inst_jump(to) }
    end

  end

  class Loop
    attr_accessor :start_index, :stop_index

    def call(machine)
      machine.inst_jump_if_zero(stop_index + 1)
    end

  end
end
