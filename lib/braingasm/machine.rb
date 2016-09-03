require "braingasm/errors"
require "braingasm/options"

module Braingasm

  # A Machine keeps the state of a running program, and exposes various
  # operations to modify this state
  class Machine
    attr_accessor :tape, :dp, :program, :ip, :ctrl_stack, :last_write, :input, :output

    def initialize
      @tape = Array.new(10) { 0 }
      @dp = 0           # data pointer
      @data_offset = 0
      @ip = 0           # instruction pointer

      @ctrl_stack = []
      @last_write = 0

      @input = ARGF
      @output = $stdout
    end

    def run
      return if @program.empty?

      loop do
        continue = step
        break unless continue && @ip < @program.size
      end
    end

    def step
      @program[@ip].call(self)
      @ip += 1
    rescue JumpSignal => jump
      @ip = jump.to
    end

    def cell
      @tape[@dp]
    end

    def cell=(new_value)
      @tape[@dp] = new_value
      trigger_cell_updated
    end

    def pos
      @dp - @data_offset
    end

    def inst_right(n=1)
      new_dp = @dp + n
      no_cells = @tape.length

      if new_dp >= no_cells
        grow = new_dp * 3 / 2
        @tape.fill(0, no_cells..grow)
      end

      @dp = new_dp
    end

    def inst_left(n=1)
      new_dp = @dp - n

      if new_dp < 0
        new_cells = -new_dp
        new_cells.times { @tape.unshift 0 }
        @data_offset += new_cells

        new_dp = 0
      end

      @dp = new_dp
    end

    def inst_print_tape
      p @tape
    end

    def inst_inc(n=1)
      @tape[@dp] += n
      trigger_cell_updated
    end

    def inst_dec(n=1)
      @tape[@dp] -= n
      trigger_cell_updated
    end

    def inst_jump(to)
      raise JumpSignal.new(to)
    end

    def inst_jump_if_data_zero(to)
      raise JumpSignal.new(to) if cell == 0
    end

    def inst_jump_if_ctrl_zero(to)
      ctrl = ctrl_stack.pop
      raise JumpSignal.new(to) if ctrl == 0
      ctrl_stack << ctrl - 1
    end

    def inst_push_ctrl(x)
      ctrl_stack << x
    end

    def inst_print(chr)
      @output.putc chr
    end

    def inst_print_cell
      @output.putc cell
    end

    def inst_read_byte
      @tape[@dp] = @input.getbyte || Options[:eof] || @tape[@dp]
      trigger_cell_updated
    end

    private
    def trigger_cell_updated
      @tape[@dp] %= Options[:cell_limit] if Options[:wrap_cells]
      @last_write = @tape[@dp]
    end
  end
end
