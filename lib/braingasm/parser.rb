require "braingasm/errors"

module Braingasm

  # Takes some input code and generates the program
  class Parser
    attr_accessor :program, :loop_stack

    def initialize(input)
      @input = input
      @program = []
      @loop_stack = []
    end

    def parse_program
      loop do
        push_instruction parse_next(@input)
      end

      raise_parsing_error("Unmatched `[`") unless @loop_stack.empty?
      @program
    end

    def parse_next(tokens)
      case tokens.next
      when :right
        right()
      when :left
        left()
      when :plus
        inc()
      when :minus
        dec()
      when :period
        print()
      when :comma
        read()
      when :loop_start
        new_loop = Loop.new
        @loop_stack.push(new_loop)
        new_loop.start_index = @program.size
        new_loop
      when :loop_end
        current_loop = @loop_stack.pop
        raise_parsing_error("Unmatched `]`") unless current_loop
        instruction = jump(current_loop.start_index)
        index = @program.size
        current_loop.stop_index = index
        instruction
      end
    end

    def push_instruction(instruction)
      return unless instruction
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

    private
    def raise_parsing_error(message)
      raise ParsingError.new(@input.line_numer, @input.column_number), message
    end
  end
end
