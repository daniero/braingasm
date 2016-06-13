require 'spec_helper'
require "braingasm/machine"

describe Braingasm::Machine do
  subject { Braingasm::Machine.new }

  it "initializes the tape, data pointer and instruction pointer" do
    expect(subject.tape).to be_an Array
    expect(subject.tape).to all be 0

    expect(subject.dp).to be 0
    expect(subject.ip).to be 0
  end

  describe :step do
    before(:each) do
      subject.ip = 1
      instruction = double()
      allow(instruction).to receive(:call).and_return(4, 2)
      subject.program = [nil, instruction, nil, nil, instruction]
    end

    it "calls the next instruction and sets IP to its return value" do
      subject.step
      expect(subject.ip).to be 4

      subject.step
      expect(subject.ip).to be 2
    end
  end

  describe "instructions" do
    it "return new value for instruction pointer" do
      # Kinda ugly, but it automatically tests methods added to the class,
      # unless they are explicitly excluded here:
      instruction_methods = subject.class.instance_methods(false).
        grep(/^inst_/) - [:inst_print_tape]

      instruction_methods.each do |name|
        subject.ip = current_ip = rand 10

        new_ip = subject.method(name).call

        expect(new_ip).to be(current_ip + 1),
          "return value of instruction `#{name}`"
      end
    end

    describe :inst_right do
      it "increases the data pointer" do
        subject.dp = 3

        subject.inst_right

        expect(subject.dp).to be 4
      end
    end

    describe :inst_left do
      it "decreases the data pointer" do
        subject.dp = 6

        subject.inst_left

        expect(subject.dp).to be 5
      end
    end

    describe :inst_inc do
      it "increases the value of the cell under the pointer" do
        subject.dp = 3

        subject.inst_inc

        expect(subject.tape[3]).to be 1
      end
    end

    describe :inst_dec do
      it "decreases the value of the cell under the pointer" do
        subject.tape = [ 0, 0, 7 ]
        subject.dp = 2

        subject.inst_dec

        expect(subject.tape[2]).to be 6
      end
    end

  end
end
