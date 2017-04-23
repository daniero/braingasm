require "braingasm/prefixes"

module Braingasm
  class Compiler
    attr_accessor :prefixes, :loop_stack

    def initialize
      @prefixes = PrefixStack.new
      @loop_stack = []
    end

    def push_prefix(prefix)
      @prefixes << prefix
      prefix
    end

    def pos
      push_prefix ->(m) { m.pos }
    end

    def random
      random = proc { |n, _| rand n }
      return_max_value = proc { |_, _| Options[:cell_limit] }
      push_prefix @prefixes.fix_params(random, return_max_value)
    end

    def zero
      push_prefix ->(m) { m.cell == 0 ? 1 : 0 }
    end

    def signed
      push_prefix ->(m) { m.last_write >= 0 ? 0 : 1 }
    end

    def parity
      push_prefix ->(m) { (m.cell &.% 2) || 0 }
    end

    def right
      @prefixes.fix_params ->(n, m) { m.inst_right(n) }
    end

    def left
      @prefixes.fix_params ->(n, m) { m.inst_left(n) }
    end

    def inc
      @prefixes.fix_params ->(n, m) { m.inst_inc(n) }
    end

    def dec
      @prefixes.fix_params ->(n, m) { m.inst_dec(n) }
    end

    def multiply
      @prefixes.fix_params ->(n, m) { m.inst_multiply(n) }, 2
    end

    def divide
      @prefixes.fix_params ->(n, m) { m.inst_divide(n) }, 2
    end

    def print
      if @prefixes.empty?
        ->(m) { m.inst_print_cell }
      else
        @prefixes.fix_params ->(n, m) { m.inst_print(n) }
      end
    end

    def print_int
      if @prefixes.empty?
        ->(m) { m.inst_print_cell_int }
      else
        @prefixes.fix_params ->(n, m) { m.inst_print_int(n) }
      end
    end

    def read
      if @prefixes.empty?
        ->(m) { m.inst_read_byte }
      else
        @prefixes.fix_params ->(n, m) { m.cell = n }
      end
    end

    def read_int
      @prefixes.fix_params ->(n, m) { m.inst_read_int(n) }, 10
    end

    def compare
      ->(m) { m.inst_compare_cells }
    end

    def quit
      @prefixes.fix_params ->(n, m) { m.inst_quit(n) }, 1
    end

    def jump(to)
      ->(m) { m.inst_jump(to) }
    end

    def loop_start(start_index)
      return prefixed_loop(start_index) unless @prefixes.empty?

      new_loop = Loop.new
      @loop_stack.push(new_loop)
      new_loop.start_index = start_index
      new_loop
    end

    def prefixed_loop(start_index)
      new_loop = FixedLoop.new
      @loop_stack.push(new_loop)
      new_loop.start_index = start_index + 1
      push_ctrl = @prefixes.fix_params ->(n, m) { m.inst_push_ctrl(n) }
      [push_ctrl, new_loop]
    end

    def loop_end(index)
      current_loop = @loop_stack.pop
      raise BraingasmError, "Unmatched `]`" unless current_loop
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

  end
end
