require "braingasm/tokenizer"
require "braingasm/parser"
require "braingasm/compiler"
require "braingasm/machine"
require "braingasm/io"

module Braingasm

  def self.run(code)
    machine = self.initialize_machine(code)
    machine.run()
  end

  def self.initialize_machine(code)
    tokenizer = Tokenizer.new(code)
    compiler = Compiler.new
    program = Parser.new(tokenizer, compiler).parse_program
    machine = Machine.new

    machine.input = InputBuffer.new($<)
    machine.output = $>
    machine.program = program
    machine
  end
end
