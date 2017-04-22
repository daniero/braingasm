require 'braingasm'
require 'braingasm/machine'

shared_context "braingasm features" do
  before do
    @machine = Braingasm::Machine.new
  end

  def run(code)
    @machine.program = Braingasm.compile(code)
    @machine.run
  end
end

RSpec.configure do |rspec|
  rspec.include_context "braingasm features", :include_shared => true
end
