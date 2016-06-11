require "braingasm/parser"
require "braingasm/machine"

module Braingasm
  def self.initialize_machine(code)
    program = Parser.new(code).parse
    machine = Machine.new
    machine.program = program
    machine
  end
end
