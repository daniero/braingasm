# encoding: UTF-8
require 'spec_helper'
require "braingasm/machine"

module Braingasm
  describe Parser do
    subject { Parser.new(@input) }

    describe "parsing" do
      it "returns an empty program for empty input" do
        @input = ""

        expect(subject.parse).to be == []
      end

      it "ignores unknown characters in the input" do
        @input = "x yz_*@^æøå"

        expect(subject.parse).to be == []
      end

      describe "simple instructions" do
        inputs = { '+' => :inc,
                   '-' => :dec,
                   '>' => :right,
                   '<' => :left,
                   '.' => :print,
                   ',' => :read }

        inputs.each do |input, instruction|
          it { should respond_to instruction }

          it "pushes an instruction '#{instruction}' given a '#{input}'" do
            @input = input
            return_value = "#{instruction}_mock_return"
            expect(subject).to receive(instruction).and_return(return_value)
            expect(subject).to receive(:push_instruction).with(return_value)

            subject.parse
          end
        end
      end

      describe "loop start" do
        before do
          @input = '['
        end

        it "adds a loop to the program with correct start index" do
          new_loop = nil
          expect(subject).
            to receive(:push_instruction) { |inst| new_loop = inst }.
            and_return(17)

          subject.parse

          expect(new_loop).to be_a Parser::Loop
          expect(new_loop.start_index).to be 17
        end

        it "pushes the loop to the loop stack" do
          expect(subject.loop_stack).to receive(:push).with(instance_of(Parser::Loop))

          subject.parse
        end
      end

      describe "loop end" do
        let(:current_loop) { Parser::Loop.new }

        before do
          @input = ']'
          subject.loop_stack = [current_loop]
        end

        it "pushes a jump instruction" do
          expect(subject).to receive(:jump).and_return("jump_return_value")
          expect(subject).to receive(:push_instruction).with("jump_return_value")

          subject.parse
        end

        it "sets the stop_index of the current loop" do
          expect(subject).to receive(:push_instruction).and_return(13)

          subject.parse

          expect(current_loop.stop_index).to be 13
        end

        it "pops the current loop off the loop stack" do
          subject.parse

          expect(subject.loop_stack).to be_empty
        end
      end
    end

    describe :push_instruction do
      it "pushes the instruction onto the program" do
        subject.push_instruction(1)
        subject.push_instruction(2)
        subject.push_instruction(3)

        expect(subject.program).to be == [1, 2, 3]
      end

      it "returns the index of the newly pushed instruction" do
        expect(subject.push_instruction(:foo)).to be 0
        expect(subject.push_instruction(:bar)).to be 1
        expect(subject.push_instruction(:baz)).to be 2
      end
    end
  end
end
