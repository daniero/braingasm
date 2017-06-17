require "braingasm/errors"
require "braingasm/options"

module Braingasm

  # A Machine keeps the state of a running program, and exposes various
  # operations to modify this state
  class Machine
    attr_accessor :tape, :dp, :program, :ip, :ctrl_stack, :last_write, :input, :output,
      :tape_limit

    def initialize
      @tape = Array.new(10) { 0 }
      @dp = 0           # data pointer
      @data_offset = 0
      @ip = 0           # instruction pointer

      @ctrl_stack = []
      @last_write = 0
    end

    def run
      step while @ip < @program.size
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

    def absolute_cell(position)
      @tape[@dp + @data_offset + position]
    end

    def pos
      @dp - @data_offset
    end

    def calculate_new_dp(move)
      if @tape_limit
        if @tape_limit >= 0
          (@dp + move) % @tape_limit
        else
          (@dp + move) % -@tape_limit
        end
      else
        @dp + move
      end
    end

    def inst_right(n=1)
      new_dp = calculate_new_dp(n)
      no_cells = @tape.length

      if new_dp >= no_cells
        grow = new_dp * 3 / 2
        @tape.fill(0, no_cells..grow)
      end

      @dp = new_dp
    end

    def inst_left(n=1)
      new_dp = calculate_new_dp(-n)

      if new_dp < 0
        new_cells = -new_dp
        new_cells.times { @tape.unshift 0 }
        @data_offset += new_cells

        @dp = 0
      else
        @dp = new_dp
      end
    end

    def inst_print_tape
      p @tape
    end

    def inst_inc(n=1)
      self.cell += n
    end

    def inst_dec(n=1)
      self.cell -= n
    end

    def inst_multiply(n=2)
      self.cell *= n
    end

    def inst_divide(n=2)
      self.cell /= n
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

    def print_bytes(b)
      d,m = b.divmod(256)

      if d > 0
        print_bytes(d)
      end

      @output.putc(m)
    end

    def inst_print(chr)
      case chr
      when Integer
        print_bytes(chr)
      else
        @output.print chr
      end
    end

    def inst_print_cell
      print_bytes(cell)
    end

    def inst_print_int(n)
      @output.print n
    end

    def inst_print_cell_int
      @output.print cell
    end

    def inst_read_byte
      self.cell = @input.getbyte || Options[:eof] || @tape[@dp]
    end

    def inst_read_int(radix=10)
      return unless @input.gets =~ /\d+/

      @input.ungetc($')
      self.cell = $&.to_i(radix)
    end

    def inst_compare_cells
      operand = @dp == 0 ? 0 : @tape[@dp-1]
      @last_write = @tape[@dp] - operand
    end

    def inst_quit(value, code=0)
      raise ExitSignal.new(code) unless value == 0
    end

    def limit_tape(cell_number)
      @tape_limit = cell_number
    end


    private
    def trigger_cell_updated
      @tape[@dp] %= Options[:cell_limit] if Options[:wrap_cells]
      @last_write = @tape[@dp]
    end
  end
end
