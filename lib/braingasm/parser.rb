require "braingasm/errors"
require "braingasm/compiler"

module Braingasm

  # Takes some input code and generates the program
  class Parser
    attr_accessor :input, :program

    def initialize(input, compiler)
      @input = input
      @compiler = compiler
      @program = []
    end

    def parse_program
      loop do
        push_instruction parse_next(@input)
      end

      raise_parsing_error("Unmatched `[`") unless @compiler.loop_stack.empty?
      @program
    end

    def parse_next(tokens)
      token = tokens.next

      case token
      when Integer
        @compiler.prefixes.push token
        false
      when :hash
        @compiler.prefixes.push ->(m) { m.pos }
        false
      when :right
        @compiler.right()
      when :left
        @compiler.left()
      when :plus
        @compiler.inc()
      when :minus
        @compiler.dec()
      when :period
        @compiler.print()
      when :comma
        @compiler.read()
      when :loop_start
        @compiler.loop_start(@program.size)
      when :loop_end
        @compiler.loop_end(@program.size)
      end
    end

    def push_instruction(instruction)
      return unless instruction

      @compiler.prefixes.clear
      @program.push(*instruction)
      @program.size - 1
    end
  end

  def raise_parsing_error(message)
    raise ParsingError.new(@input.line_numer, @input.column_number), message
  end
end
