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
      when :right
        @compiler.right
      when :left
        @compiler.left
      when :increment
        @compiler.inc
      when :decrement
        @compiler.dec
      when :multiply
        @compiler.multiply
      when :divide
        @compiler.divide
      when :print
        @compiler.print
      when :output
        @compiler.print_int
      when :read
        @compiler.read
      when :input
        @compiler.read_int
      when :compare
        @compiler.compare
      when :quit
        @compiler.quit
      when :tape_limit
        @compiler.tape_limit
      when :loop_start
        @compiler.loop_start(@program.size)
      when :loop_end
        @compiler.loop_end(@program.size)
      else
        case token
        when Integer, String
          @compiler.push_prefix token
        when :value
          @compiler.read_cell
        when :position
          @compiler.pos
        when :random
          @compiler.random
        when :zero
          @compiler.zero
        when :non_zero
          @compiler.non_zero
        when :signed
          @compiler.signed
        when :parity
          @compiler.parity
        when :oddity
          @compiler.oddity
        when :prime
          @compiler.prime
        end
        false
      end
    rescue BraingasmError => e
      raise_parsing_error(e.message)
    end

    def push_instruction(instruction)
      return unless instruction
      @program.push(*instruction)
      @program.size - 1
    end

    def raise_parsing_error(message)
      raise ParsingError.new(@input.line_numer, @input.column_number), message
    end
  end
end
