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

    def eval_prefixes(n)
      prefixes = @prefixes.pop(n)
      ->(m) { yield(m, *prefixes.map { |p| p.is_a?(Proc) ? p[m] : p }) }
    end

    READ_CELL = ->(n, m) { m.cell }
    def read_cell
      push_prefix @prefixes.fix_params(READ_CELL)
    end

    def pos
      push_prefix ->(m) { m.pos }
    end

    def random
      if @prefixes.empty?
        push_prefix @prefixes.fix_params(->(_, _) { Options[:cell_limit] })
      end

      if @prefixes.length == 1
        push_prefix @prefixes.fix_params(->(n, _) { rand n })
      else
        push_prefix eval_prefixes(2) { |_, min, max| rand(max-min + 1) + min }
      end
    end

    def zero
      read_cell if @prefixes.empty?

      push_prefix eval_prefixes(1) { |_,n| n.zero? ? 1 : 0 }
    end

    def signed
      read_cell if @prefixes.empty?

      push_prefix eval_prefixes(1) { |_, n| n < 0 ? 1 : 0 }
    end

    def parity
      if @prefixes.last.is_a?(Integer)
        x = @prefixes.pop
        read_cell if @prefixes.empty?
        push_prefix @prefixes.fix_params(->(n, m) { n % x == 0 ? 1 : 0 })
      elsif @prefixes.length >= 2
        push_prefix eval_prefixes(2) { |_, n, y| y % n == 0 ? 1 : 0 }
      else
        read_cell if @prefixes.empty?
        push_prefix @prefixes.fix_params(->(n, m) { (n % 2) ^ 1 })
      end
    end

    def oddity
      parity
      push_prefix eval_prefixes(1) { |_, x| x ^ 1 }
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
      elsif @prefixes.first.is_a? String
        string = @prefixes.first

        @prefixes.fix_params ->(n, m) {
          from, to = m.dp, m.dp + string.size

          if m.tape_limit && to > m.tape_limit
            limit = m.tape_limit
            cutoff = to - limit

            m.tape[from..limit] = string.bytes[0..cutoff]
            m.tape[0...cutoff] = string.bytes[(cutoff+1)..-1]
          else
            m.tape[from...to] = string.bytes
          end
        }
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

    def tape_limit
      if @prefixes.empty?
        push_prefix ->(m) { x = m.pos; x + (x < 0 ? -1 : 1) }
      end

      @prefixes.fix_params ->(n, m) { m.limit_tape(n) }
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
