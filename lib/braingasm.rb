require "braingasm/tokenizer"
require "braingasm/parser"
require "braingasm/compiler"
require "braingasm/machine"

module Braingasm
  def self.initialize_machine(code)
    machine = Machine.new
    tokenizer = Tokenizer.new(code)
    compiler = Compiler.new
    machine.program = Parser.new(tokenizer, compiler).parse_program
    machine
  end
end
