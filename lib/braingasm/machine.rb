module Braingasm

  VMError = Class.new(RuntimeError)

  # A Machine keeps the state of a running program, and exposes various
  # operations to modify this state
  class Machine
    attr_accessor :tape, :dp, :program, :ip

    def initialize
      @tape = Array.new(10) { 0 }
      @dp = 0           # data pointer
      @ip = 0           # instruction pointer
    end

    def run
      loop do
        continue = step
        break unless continue && @ip < @program.size
      end
    end

    def step
      move = @program[@ip].call(self)
      @ip = move
    end

    def inst_right(n=1)
      new_dp = @dp + n
      no_cells = @tape.length

      if new_dp >= no_cells
        grow = new_dp * 3 / 2
        @tape.fill(0, no_cells..grow)
      end

      @dp = new_dp
      @ip + 1
    end

    def inst_left(n=1)
      @dp -= 1
      raise VMError, "Moved outside the tape" if @dp < 0
      @ip + 1
    end

    def inst_print_tape
      p @tape
      @ip + 1
    end

    def inst_inc(n=1)
      @tape[@dp] += n
      @ip + 1
    end

    def inst_dec(n=1)
      @tape[@dp] -= n
      @ip + 1
    end

    def inst_jump(to)
      to
    end

    def inst_jump_if_zero(to)
      @tape[@dp] == 0 ? to : @ip + 1
    end

    def inst_print_cell
      print @tape[@dp].chr
      @ip + 1
    end

    def inst_read_byte
      @tape[@dp] = $stdin.getbyte || 0
      @ip + 1
    end

  end
end
