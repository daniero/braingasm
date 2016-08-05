module Braingasm

  ParsingError = Class.new(RuntimeError)

  # Takes some input code and generates the program
  class Parser
    attr_accessor :program, :loop_stack

    def initialize(input)
      @input = input
      @program = []
      @loop_stack = []
    end

    def parse
      tokens = @input.scan(/\S/)

      tokens.each do |token|
        case token
        when '>'
          push_instruction right()
        when '<'
          push_instruction left()
        when '+'
          push_instruction inc()
        when '-'
          push_instruction dec()
        when '.'
          push_instruction print()
        when ','
          push_instruction read()
        when '['
          new_loop = Loop.new
          @loop_stack.push(new_loop)
          index = push_instruction(new_loop)
          new_loop.start_index = index
        when ']'
          current_loop = @loop_stack.pop
          raise ParsingError, "Unmatched `]`" unless current_loop
          instruction = jump(current_loop.start_index)
          index = push_instruction(instruction)
          current_loop.stop_index = index
        end
      end
      @program
    end

    def push_instruction(instruction)
      @program.push instruction
      @program.size - 1
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

    class Loop
      attr_accessor :start_index, :stop_index

      def call(machine)
        machine.inst_jump_if_zero(stop_index + 1)
      end

    end
  end
end
