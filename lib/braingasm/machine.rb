require "braingasm/errors"
require "braingasm/options"

module Braingasm

  # A Machine keeps the state of a running program, and exposes various
  # operations to modify this state
  class Machine
    attr_accessor :tape, :dp, :program, :ip, :ctrl_stack

    def initialize
      @tape = Array.new(10) { 0 }
      @dp = 0           # data pointer
      @ip = 0           # instruction pointer
      @ctrl_stack = []
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
        n.times do
          @tape.unshift 0
        end
        new_dp = 0
      end

      @dp = new_dp
    end

    def inst_print_tape
      p @tape
    end

    def inst_inc(n=1)
      @tape[@dp] += n
      wrap_cell
    end

    def inst_dec(n=1)
      @tape[@dp] -= n
      wrap_cell
    end

    def inst_jump(to)
      raise JumpSignal.new(to)
    end

    def inst_jump_if_data_zero(to)
      raise JumpSignal.new(to) if @tape[@dp] == 0
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
      putc chr
    end

    def inst_print_cell
      putc @tape[@dp]
    end

    def inst_set_value(v)
      @tape[@dp] = v
    end

    def inst_read_byte
      @tape[@dp] = ARGF.getbyte || Options[:eof] || @tape[@dp]
    end

    private
    def wrap_cell
      @tape[@dp] %= Options[:cell_limit] if Options[:wrap_cells]
    end
  end
end
