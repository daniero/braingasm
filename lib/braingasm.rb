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
    machine = Machine.new

    machine.program = compile(code)
    machine.input = InputBuffer.new($<)
    machine.output = $>
    machine
  end

  def self.compile(code)
    tokenizer = Tokenizer.new(code)
    compiler = Compiler.new
    parser = Parser.new(tokenizer, compiler)

    parser.parse_program
  end
end
