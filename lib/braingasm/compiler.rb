module Braingasm
  class Compiler
    attr_accessor :prefixes, :loop_stack

    def initialize
      @prefixes = []
      @loop_stack = []
    end

    def push_prefix(prefix)
      @prefixes << prefix
    end

    def fix_params(function, default_param=1)
      prefix = @prefixes.pop || default_param

      case prefix
      when Integer
        function.curry.call(prefix)
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
        ->(m) { m.inst_print_cell }
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
      push_ctrl = fix_params ->(n, m) { m.inst_push_ctrl(n) }
      [push_ctrl, new_loop]
    end

    def loop_end(index)
      current_loop = @loop_stack.pop
      raise_parsing_error("Unmatched `]`") unless current_loop
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
