require "braingasm/parser"
require "braingasm/machine"

module Braingasm
  def self.initialize_machine(code)
    machine = Machine.new
    machine.program = Parser.new(code).parse_program
    machine
  end
end
