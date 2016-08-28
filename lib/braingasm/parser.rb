require "braingasm/errors"

module Braingasm

  # Takes some input code and generates the program
  class Parser
    attr_accessor :input, :program, :loop_stack, :prefixes

    def initialize(input)
      @input = input
      @program = []
      @loop_stack = []
      @prefixes = []
    end

    def parse_program
      loop do
        push_instruction parse_next(@input)
      end

      raise_parsing_error("Unmatched `[`") unless @loop_stack.empty?
      @program
    end

    def parse_next(tokens)
      token = tokens.next

      case token
      when Integer
        @prefixes.push token
        false
      when :hash
        @prefixes.push -> m { m.pos }
        false
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
        loop_start()
      when :loop_end
        loop_end()
      end
    end

    def push_instruction(instruction)
      return unless instruction

      @prefixes.clear
      @program.push(*instruction)
      @program.size - 1
    end

    def fix_params(function, default_param=1)
      prefix = @prefixes.pop || default_param

      case prefix
      when Integer
        function.curry[prefix]
      when Proc
        Proc.new do |m|
          n = prefix.call(m)
          function.call(n, m)
        end
      end
    end

    def right()
      fix_params ->(n, m) { m.inst_right(n) }
    end

    def left()
      fix_params ->(n, m) { m.inst_left(n) }
    end

    def inc()
      fix_params ->(n, m) { m.inst_inc(n) }
    end

    def dec()
      fix_params ->(n, m) { m.inst_dec(n) }
    end

    def print()
      if @prefixes.empty?
        ->(m){ m.inst_print_cell }
      else
        fix_params ->(n, m) { m.inst_print(n) }
      end
    end

    def read()
      if @prefixes.empty?
        ->(m) { m.inst_read_byte }
      else
        fix_params ->(n, m) { m.inst_set_value(n) }
      end
    end

    def jump(to)
      ->(m) { m.inst_jump(to) }
    end

    def loop_start()
      return prefixed_loop() unless @prefixes.empty?

      new_loop = Loop.new
      @loop_stack.push(new_loop)
      new_loop.start_index = @program.size
      new_loop
    end

    def prefixed_loop()
      new_loop = FixedLoop.new
      @loop_stack.push(new_loop)
      new_loop.start_index = @program.size + 1
      push_ctrl = fix_params ->(n, m) { m.inst_push_ctrl(n) }
      [push_ctrl, new_loop]
    end

    def loop_end
      current_loop = @loop_stack.pop
      raise_parsing_error("Unmatched `]`") unless current_loop
      index = @program.size
      current_loop.stop_index = index
      jump(current_loop.start_index)
    end

    class Loop
      attr_accessor :start_index, :stop_index

      def call(machine)
        machine.inst_jump_if_data_zero(stop_index + 1)
      end
    end

    class FixedLoop < Loop
      def call(machine)
        machine.inst_jump_if_ctrl_zero(stop_index + 1)
      end
    end

    def raise_parsing_error(message)
      raise ParsingError.new(@input.line_numer, @input.column_number), message
    end
  end
end
