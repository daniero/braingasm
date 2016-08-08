require "braingasm/tokenizer"
require "braingasm/parser"
require "braingasm/machine"

module Braingasm
  def self.initialize_machine(code)
    machine = Machine.new
    tokenizer = Tokenizer.new(code)
    machine.program = Parser.new(tokenizer).parse_program
    machine
  end
end
