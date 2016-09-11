# encoding: UTF-8
require 'spec_helper'
require "braingasm/machine"

describe Braingasm::Machine do
  subject { Braingasm::Machine.new }

  it "initializes all fields" do
    expect(subject.tape).to be_an Array
    expect(subject.tape).to all be 0

    expect(subject.dp).to be 0
    expect(subject.ip).to be 0

    expect(subject.ctrl_stack).to be_an Array
    expect(subject.ctrl_stack).to be_empty

    expect(subject.last_write).to be 0
  end

  describe "#run" do
    it "can handle an empty program" do
      subject.program = []

      subject.run
    end
  end

  describe "#step" do
    before(:each) do
      subject.program = []
      subject.ip = 0
    end

    it "calls the next instruction in the program and advances the instruction pointer" do
      5.times do |i|
        instruction = double
        expect(instruction).to receive(:call).with(subject).ordered
        subject.program << instruction

        subject.step

        expect(subject.ip).to be == i + 1
      end
    end

    it "updates the instruction pointer accordingly if a JumpSignal is raised" do
      instruction = double
      expect(instruction).to receive(:call).with(subject).and_raise Braingasm::JumpSignal.new(7)
      subject.program << instruction

      subject.step

      expect(subject.ip).to be 7
    end
  end

  describe "#cell" do
    it "returns the value of the cell under the cursor" do
      subject.tape = [1, 2, 4]
      expect(subject.cell).to be 1

      subject.dp = 1
      expect(subject.cell).to be 2

      subject.dp = 2
      expect(subject.cell).to be 4
    end
  end

  shared_examples "cell update" do
    after { expect(subject.last_write).to be subject.cell }
  end

  describe "#cell=" do
    include_examples "cell update"

    it "sets the value of the cell under the cursor" do
      subject.tape = [0, 0, 0]
      subject.cell = 1
      expect(subject.tape).to be == [1, 0, 0]

      subject.dp = 1
      subject.cell = 3
      expect(subject.tape).to be == [1, 3, 0]

      subject.dp = 2
      subject.cell = 5
      expect(subject.tape).to be == [1, 3, 5]
    end
  end

  describe "#pos" do
    it "returns the position of the datapointer relative to the initial first cell" do
      expect(subject.pos).to be(0)

      subject.inst_right
      expect(subject.pos).to be(1)

      subject.inst_right(7)
      expect(subject.pos).to be(8)

      subject.inst_left(8)
      expect(subject.pos).to be(0)

      subject.inst_left
      expect(subject.pos).to be(-1)

      subject.inst_left(3)
      expect(subject.pos).to be(-4)

      subject.inst_right(2)
      subject.inst_left(3)
      expect(subject.pos).to be(-5)
    end
  end

  describe "instructions" do
    describe "#inst_right" do
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

    describe "#inst_left" do
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

        it "shifts new cells onto the start of the tape, keeping a positive data pointer index" do
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

    describe "#inst_inc" do
      include_examples "cell update"

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

    describe "#inst_dec" do
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

    describe "#inst_jump" do
      it "raises a JumpSignal, interupting normal program flow" do
        expect{ subject.inst_jump(:foo) }.to raise_error Braingasm::JumpSignal
      end
    end

    describe "#inst_jump_if_data_zero" do
      before(:each) do
        subject.tape = [ 0, 0, 7 ]
      end

      it "does nothing if the current cell value if not zero" do
        subject.dp = 2

        subject.inst_jump_if_data_zero(1000)
      end

      it "raises a JumpSignal if the current cell value is zero" do
        subject.dp = 1

        expect{ subject.inst_jump_if_data_zero(99) }.to raise_error { |error|
          expect(error).to be_a Braingasm::JumpSignal
          expect(error.to).to be 99
        }
      end
    end

    describe "#inst_push_ctrl" do
      it "pushes the given value to the control stack" do
        subject.inst_push_ctrl 1
        expect(subject.ctrl_stack).to eq [1]

        subject.inst_push_ctrl 2
        expect(subject.ctrl_stack).to eq [1, 2]
      end
    end

    describe "#inst_jump_if_ctrl_zero" do
      context "when the top of the control stack is zero" do
        before { subject.ctrl_stack << 0 }

        it "pops the top of the control stack and jumps to the given instruction number" do
          expect { subject.inst_jump_if_ctrl_zero(10) }.to raise_error { |jump_signal|
            expect(jump_signal.to).to be 10
          }

          expect(subject.ctrl_stack).to be_empty
        end
      end

      context "otherwise" do
        before(:each) { subject.ctrl_stack << 100 }

        it "decreases the top of the control stack" do
          subject.inst_jump_if_ctrl_zero(42)

          expect(subject.ctrl_stack).to eq([99])
        end
      end
    end

    describe "output" do
      let(:output) { instance_double(IO) }
      before { subject.output = output }

      describe "#inst_print" do
        it "prints the ASCII value of the given parameter through the given output" do
          expect(output).to receive(:putc).with(72)
          subject.inst_print(72)

          expect(output).to receive(:putc).with(105)
          subject.inst_print(105)
        end
      end

      describe "#inst_print_cell" do
        it "outputs the value of the current cell as a byte" do
          subject.tape = [ 70 ]
          expect(output).to receive(:putc).with(70)

          subject.inst_print_cell()
        end
      end

      describe "#inst_print_cell_int" do
        it "prints the value of the current cell" do
          subject.tape = [ 1234 ]
          expect(output).to receive(:print).with(1234)

          subject.inst_print_cell_int()
        end
      end

      describe "#inst_print_int" do
        it "prints the value of the current cell" do
          expect(output).to receive(:print).with(99)

          subject.inst_print_int(99)
        end
      end
    end

    describe "#inst_read_byte" do
      before { subject.input = StringIO.new("Hiæ") }

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
        before { subject.input = StringIO.new("") }

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
            before do
              Braingasm::Options[:eof] = option_value
              # Can't store -1 in the cell with cell wrapping on:
              Braingasm::Options[:wrap_cells] = false
            end

            it "changes the value of the current cell to #{option_value}" do
              subject.tape[0] = 77

              subject.inst_read_byte

              expect(subject.tape[0]).to be option_value
            end
          end
        end
      end
    end

    describe "#inst_read_int" do
      include_examples "cell update"
      before { subject.input = StringIO.new("123   456") }

      it "reads an integer from the input stream" do
        subject.inst_read_int()
        expect(subject.cell).to be(123)

        subject.inst_read_int()
        expect(subject.cell).to be(456)
      end
    end

    describe "#inst_compare_cells" do
      before do
        subject.tape = [1, 3, 6, 10]
      end

      it "updates last write value to current cell value minus cell value to the left" do
        subject.dp = 1
        subject.inst_compare_cells
        expect(subject.last_write).to be(3 - 1)

        subject.dp = 2
        subject.inst_compare_cells
        expect(subject.last_write).to be(6 - 3)

        subject.dp = 3
        subject.inst_compare_cells
        expect(subject.last_write).to be(10 - 6)
      end

      it "compares the leftmost cell on the tape with 0" do
        subject.inst_compare_cells

        expect(subject.last_write).to be(1 - 0)
      end
    end

  end
end
