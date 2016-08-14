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

  describe "instructions" do
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
      it "raises a JumpSignal, interupting normal program flow" do
        expect{ subject.inst_jump(:foo) }.to raise_error Braingasm::JumpSignal
      end
    end

    describe :inst_jump_if_zero do
      before(:each) do
        subject.tape = [ 0, 0, 7 ]
      end

      it "does nothing if the current cell value if not zero" do
        subject.dp = 2

        subject.inst_jump_if_zero(1000)
      end

      it "raises a JumpSignal if the current cell value is zero" do
        subject.dp = 1

        expect{ subject.inst_jump_if_zero(99) }.to raise_error { |error|
          expect(error).to be_a Braingasm::JumpSignal
          expect(error.to).to be 99
        }
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
    end
  end
end
