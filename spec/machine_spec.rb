# encoding: UTF-8
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

  describe :run do
    it "can handle an empty program" do
      subject.program = []

      subject.run
    end
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
        grep(/^inst_/).grep_v(/jump/) - [:inst_print_tape, :inst_read_byte]

      instruction_methods.each do |name|
        subject.ip = current_ip = rand 10

        new_ip = subject.method(name).call

        expect(new_ip).to be(current_ip + 1),
          "return value of instruction `#{name}`"
      end
    end

    describe :inst_right do
      before { subject.tape = [] }

      it "increases the data pointer" do
        subject.dp = 3

        subject.inst_right

        expect(subject.dp).to be 4
      end

      it "can go more than one at a time" do
        subject.inst_right(123)

        expect(subject.dp).to be 123
      end

      it "can go beyond the current end of the tape" do
        100.times do |i|
          subject.inst_right

          expect(subject.tape.length).to be > i + 1
        end
      end

      it "initializes new cells" do
        expect(subject.dp).to be 0
        subject.inst_right(78)

        expect(subject.tape).to all be 0
        expect(subject.tape.length).to be > 78
      end
    end

    describe :inst_left do
      before(:each) do
        subject.tape = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        subject.dp = 6
      end

      it "decreases the data pointer" do
        subject.inst_left

        expect(subject.dp).to be 5
      end

      context "at the leftmost cell" do
        before(:each) { subject.dp = 0 }

        it "shifts new cells onto the tape to the right, keeping a positive data pointer index" do
          subject.inst_left

          expect(subject.dp).to be >= 0
        end

        it "preserves the original values on the tape" do
          subject.inst_left

          (1..10).each do |i|
            expect(subject.tape[subject.dp + i]).to be i
          end
        end

        it "initializes the newly created cells" do
          subject.inst_left

          expect(subject.tape[0..subject.dp]).to all be 0
        end
      end
    end

    describe :inst_inc do
      it "increases the value of the cell under the pointer" do
        subject.dp = 3

        subject.inst_inc

        expect(subject.tape[3]).to be 1
      end

      context "with cell wrapping off" do
        before do
          Braingasm::Options[:wrap_cells] = false
          Braingasm::Options[:cell_limit] = 256
        end

        it "increases the cell values beyond :cell_limit" do
          subject.tape[0] = 255

          subject.inst_inc

          expect(subject.tape[0]).to be 256
        end
      end

      context "with cell wrapping on" do
        before do
          Braingasm::Options[:wrap_cells] = true
          Braingasm::Options[:cell_limit] = 256
        end

        it "wraps the cell values around before reaching :cell_limit" do
          subject.tape[0] = 255

          subject.inst_inc

          expect(subject.tape[0]).to be 0
        end
      end
    end

    describe :inst_dec do
      it "decreases the value of the cell under the pointer" do
        subject.tape = [ 0, 0, 7 ]
        subject.dp = 2

        subject.inst_dec

        expect(subject.tape[2]).to be 6
      end

      context "with cell wrapping off" do
        before do
          Braingasm::Options[:wrap_cells] = false
        end

        it "goes under zero" do
          subject.inst_dec

          expect(subject.tape[0]).to be (-1)
        end
      end

      context "with cell wrapping on" do
        before do
          Braingasm::Options[:wrap_cells] = true
          Braingasm::Options[:cell_limit] = 256
        end

        it "wraps around after zero" do
          subject.inst_dec

          expect(subject.tape[0]).to be 255
        end
      end
    end

    describe :inst_jump do
      it "returns the given value, signifying the new instruction pointer" do
        expect(subject.inst_jump(9)).to be 9
        expect(subject.inst_jump(4)).to be 4
      end
    end

    describe :inst_jump_if_zero do
      it "returns the given value if value of current cell is 0" do
        expect(subject.inst_jump_if_zero(11)).to be 11
        expect(subject.inst_jump_if_zero(7)).to be 7
      end

      it "returns one plus IP if value of current cell is not 0" do
        subject.ip = 99
        subject.tape = [ 1, 0, 7 ]
        subject.dp = 2

        expect(subject.inst_jump_if_zero(1)).to be 100
        expect(subject.inst_jump_if_zero(14)).to be 100
        expect(subject.inst_jump_if_zero(42)).to be 100
      end
    end

    describe :inst_print_cell do
      it "outputs the value of the current cell as a byte" do
        subject.tape = [ 70 ]

        expect { subject.inst_print_cell }.to output('F').to_stdout
      end
    end

    describe :inst_read_byte do
      before do
        stub_const('ARGF', StringIO.new("Hiæ"))
      end

      it "reads one byte from ARGF and stores in the current cell"  do
        subject.inst_read_byte
        expect(subject.tape[0]).to be 'H'.ord

        subject.inst_read_byte
        expect(subject.tape[0]).to be 'i'.ord

        subject.inst_read_byte
        expect(subject.tape[0]).to be 195

        subject.inst_read_byte
        expect(subject.tape[0]).to be 166
      end

      context "on EOF" do
        before(:each) { stub_const 'ARGF', StringIO.new("") }

        context "if Options[:eof] is nil" do
          before { Braingasm::Options[:eof] = nil }

          it "leaves the value of the current cell unchanged" do
              subject.tape[0] = 13

              subject.inst_read_byte

              expect(subject.tape[0]).to be 13
          end
        end

        [-1, 0].each do |option_value|
          context "if Options[:eof] is #{option_value}" do
            before { Braingasm::Options[:eof] = option_value }

            it "changes the value of the current cell to #{option_value}" do
              subject.tape[0] = 77

              subject.inst_read_byte

              expect(subject.tape[0]).to be option_value
            end
          end
        end
      end

      it "returns one plus IP, allowing the program to advance" do
        subject.ip = 9

        expect(subject.inst_read_byte).to be 10
      end
    end
  end
end
