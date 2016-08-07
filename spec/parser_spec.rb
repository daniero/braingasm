# encoding: UTF-8
require 'spec_helper'
require "braingasm/machine"

module Braingasm
  describe Parser do
    subject { Parser.new(@input) }

    describe :tokenize_input do
      before { @input = "abc _\t\n+-<> " }

      it "returns an enumerator with all non-whitespace characters" do
        tokens = subject.tokenize_input()

        expect(tokens.next).to be == 'a'
        expect(tokens.next).to be == 'b'
        expect(tokens.next).to be == 'c'
        expect(tokens.next).to be == '_'
        expect(tokens.next).to be == '+'
        expect(tokens.next).to be == '-'
        expect(tokens.next).to be == '<'
        expect(tokens.next).to be == '>'
        expect { tokens.next }.to raise_error StopIteration
      end
    end

    describe :parse_program do
      it "feeds tokenized input to #parse_next" do
        tokens = [:foobar]
        expect(subject).to receive(:tokenize_input).and_return(tokens)
        expect(subject).to receive(:parse_next).with(tokens).and_raise(StopIteration)

        subject.parse_program
      end

      it "pushes each value returned by #parse_next individually" do
        tokens = [1, 2, 3].to_enum
        allow(subject).to receive(:tokenize_input).and_return(tokens)
        allow(subject).to receive(:parse_next).with(tokens) { tokens.next * 10 }
        expect(subject).to receive(:push_instruction).with(10).ordered
        expect(subject).to receive(:push_instruction).with(20).ordered
        expect(subject).to receive(:push_instruction).with(30).ordered

        subject.parse_program
      end

      it "returns an empty program for empty input" do
        @input = ""

        expect(subject.parse_program).to be == []
      end

      it "ignores unknown tokens in the input" do
        @input = "x yz_*@^æøå"

        expect(subject.parse_program).to be == []
      end

      it "fails if there are unclosed loops in the input" do
        @input = "["

        expect { subject.parse_program }.to raise_error(ParsingError)
      end
    end

    describe :parse_next do
      def input_as_token_enum(input)
        input.chars.to_enum
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

          it "returns instruction '#{instruction}' given a '#{input}'" do
            mock_generated_instruction = "#{instruction}_mock_return"
            expect(subject).to receive(instruction).and_return(mock_generated_instruction)

            response = subject.parse_next(input_as_token_enum(input))

            expect(response).to be(mock_generated_instruction)
          end
        end
      end

      describe "loop start" do
        let(:input) { input_as_token_enum('[') }

        it "returns a loop with correct start index" do
          subject.program = [nil] * 17

          response = subject.parse_next(input)

          expect(response).to be_a Parser::Loop
          expect(response.start_index).to be 17
        end

        it "pushes the loop to the loop stack" do
          response = subject.parse_next(input)

          expect(subject.loop_stack.pop).to be response
        end
      end

      describe "loop end" do
        let(:input) { input_as_token_enum(']') }
        let(:current_loop) { Parser::Loop.new }

        before do
          subject.loop_stack = [current_loop]
        end

        it "fails if there is no loop object on the loop stack" do
          subject.loop_stack = []

          expect { subject.parse_next(input) }.to raise_error(ParsingError)
        end

        it "returns a jump instruction back to the start of the current loop" do
          current_loop.start_index = 42
          expect(subject).to receive(:jump).with(42).and_return("jump_return_value")

          expect(subject.parse_next(input)).to eq("jump_return_value")
        end

        it "sets the stop_index of the current loop" do
          subject.program = [nil] * 13

          subject.parse_next(input)

          expect(current_loop.stop_index).to be 13
        end

        it "pops the current loop off the loop stack" do
          subject.parse_next(input)

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
