# encoding: UTF-8
require 'spec_helper'
require "braingasm/machine"
require "braingasm/compiler"

module Braingasm
  describe Parser do
    let(:compiler) { instance_double(Compiler) }
    subject { Parser.new(@input, compiler) }
    let(:machine) { instance_double(Machine) }

    it "initializes all necessary fields" do
      @input = :something

      expect(subject.input).to be :something
      expect(subject.program).to be_an Array
      expect(subject.program).to be_empty
    end

    def provide_input(*tokens)
      tokenizer = instance_double(Tokenizer)
      enum = tokens.to_enum
      allow(tokenizer).to receive(:next) { enum.next }
      @input = tokenizer
    end

    describe "#parse_program" do
      before do
        provide_input(*[]) # I.e, no input
        allow(compiler).to receive(:loop_stack).and_return [] 
      end

      it "returns an empty program for empty input" do
        expect(subject.parse_program).to be == []
      end

      it "calls #parse_next with the tokenizer input until it raises StopIteration" do
        tokenizer = provide_input :foo
        expect(subject).to receive(:parse_next).with(tokenizer).and_raise(StopIteration)

        subject.parse_program
      end

      it "pushes each instruction returned by #parse_next individually with #push_instruction" do
        @input = [1, 2, 3].to_enum
        allow(subject).to receive(:parse_next).with(@input) { |arg| arg.next * 10 }
        expect(subject).to receive(:push_instruction).with(10).ordered
        expect(subject).to receive(:push_instruction).with(20).ordered
        expect(subject).to receive(:push_instruction).with(30).ordered

        subject.parse_program
      end

      it "ignores unknown tokens in the input" do
        provide_input(:unknown, :foo, :bar)

        expect(subject.parse_program).to be == []
      end

      it "fails if there are unclosed loops in the input" do
        allow(subject).to receive(:raise_parsing_error).with(any_args).and_raise ParsingError

        expect { subject.parse_program }.to raise_error(ParsingError)
      end
    end

    describe "#parse_next" do
      subject { Parser.new(nil, compiler) }

      it "raises StopIteration on end of input" do
        empty = [].to_enum

        expect { subject.parse_next(empty) }.to raise_error StopIteration
      end

      describe "simple instructions" do
        inputs = { :plus => :inc,
                   :minus => :dec,
                   :right => :right,
                   :left => :left,
                   :period => :print,
                   :comma => :read,
                   :loop_start => :loop_start,
                   :loop_end => :loop_end }

        inputs.each do |token, instruction|
          it { should respond_to instruction }

          it "returns instruction '#{instruction}' given a :#{token}" do
            provide_input(token)
            mock_generated_instruction = "#{instruction}_mock_return"
            expect(subject).to receive(instruction).and_return(mock_generated_instruction)

            response = subject.parse_next(@input)

            expect(response).to be(mock_generated_instruction)
          end
        end
      end

      describe "prefixes" do
        context "when given an Integer" do
          before(:each) { provide_input(32) }

          it "returns nothing, so that it shouldn't be added as an instruction in the program" do
            expect(subject.parse_next(@input)).to be_falsy
          end

          it "adds the Integer as a prefix" do
            subject.parse_next(@input)

            expect(subject.prefixes).to be == [32]
          end
        end

        context "when given a :hash" do
          before(:each) { provide_input(:hash) }

          it "returns nothing, so that it shouldn't be added as an instruction in the program" do
            expect(subject.parse_next(@input)).to be_falsy
          end

          it "pushes an instruction to the prefix list which gets the machine's current position" do
            expect(machine).to receive(:pos).and_return 69

            subject.parse_next(@input)

            instruction = subject.prefixes.last
            instruction.call(machine)
          end
        end

      end
    end

    describe "generating instructions" do
      shared_examples "simple instruction" do |method_name, machine_instruction, arg:nil|
        it "generates a function which calls the given machine's ##{machine_instruction}" do
          expect(machine).to receive(machine_instruction).with(arg || no_args)

          generated_instruction = subject.method(method_name).call

          generated_instruction.call(machine)
        end
      end

      shared_examples "prefixed instruction" do |method_name, machine_instruction|
        context "given an integer prefix" do
          before(:each) { subject.prefixes << 42 }

          include_examples "simple instruction", method_name, machine_instruction, arg:42
        end
      end

      describe "#inc" do
        include_examples "simple instruction", :inc, :inst_inc, arg:1
        include_examples "prefixed instruction", :inc, :inst_inc
      end

      describe "#dec" do
        include_examples "simple instruction", :dec, :inst_dec, arg:1
        include_examples "prefixed instruction", :dec, :inst_dec
      end

      describe "#right" do
        include_examples "simple instruction", :right, :inst_right, arg:1
        include_examples "prefixed instruction", :right, :inst_right
      end

      describe "#left" do
        include_examples "simple instruction", :left, :inst_left, arg:1
        include_examples "prefixed instruction", :left, :inst_left
      end

      describe "#print" do
        include_examples "simple instruction", :print, :inst_print_cell
        include_examples "prefixed instruction", :print, :inst_print
      end

      describe "#read" do
        include_examples "simple instruction", :read, :inst_read_byte
        include_examples "prefixed instruction", :read, :inst_set_value
      end

      describe "#loop_start" do
        context "without prefix" do
          it "returns a loop with correct start index" do
            subject.program = [nil] * 17

            response = subject.loop_start()

            expect(response).to be_a Parser::Loop
            expect(response.start_index).to be 17
          end

          it "pushes the loop to the loop stack" do
            response = subject.loop_start()

            expect(subject.loop_stack).to be == [response]
          end
        end

        context "with number prefix" do
          before(:each) { subject.prefixes << 100 }
          let (:return_values) { subject.loop_start() }

          it "returns two instructions" do
            expect(return_values).to be_an Array
            expect(return_values.size).to be 2
          end

          describe "first instruction" do
            it "calls machine's #inst_push_ctrl with the prefix" do
              expect(machine).to receive(:inst_push_ctrl).with(100)

              return_values.first.call(machine)
            end
          end

          describe "second instruction" do
            before { subject.program = [nil] * 10 }

            it "is a fixed loop with correct start index" do
              expect(return_values.last).to be_a Parser::Loop
              expect(return_values.last.start_index).to be 11
            end

            it "is pushed to the loop stack" do
              expect(subject.loop_stack).to be == [return_values.last]
            end
          end
        end
      end

      describe "#loop_end" do
        let(:current_loop) { Parser::Loop.new }

        before do
          subject.loop_stack = [current_loop]
        end

        it "fails if there is no loop object on the loop stack" do
          subject.loop_stack = []
          allow(subject).to receive(:raise_parsing_error).with(any_args).and_raise ParsingError

          expect { subject.loop_end() }.to raise_error(ParsingError)
        end

        it "returns a jump instruction back to the start of the current loop" do
          current_loop.start_index = 42
          expect(subject).to receive(:jump).with(42).and_return("jump_return_value")

          expect(subject.loop_end()).to eq("jump_return_value")
        end

        it "sets the stop_index of the current loop" do
          subject.program = [nil] * 13

          subject.loop_end()

          expect(current_loop.stop_index).to be 13
        end

        it "pops the current loop off the loop stack" do
          subject.loop_end()

          expect(subject.loop_stack).to be_empty
        end
      end
    end

    describe "#raise_parsing_error" do
      it "raises a ParsingError with the correct line and column numbers" do
        tokenizer = provide_input :foo
        expect(tokenizer).to receive(:line_numer).and_return 100
        expect(tokenizer).to receive(:column_number).and_return 200
        error = nil

        expect { subject.raise_parsing_error("foobar") }.to raise_error(ParsingError) { |e| error = e }
        expect(error.line).to be 100
        expect(error.column).to be 200
      end
    end

    describe "#push_instruction" do
      before(:each) { subject.prefixes = [:a, :b, :c] }

      it "does nothing if the parameter is falsy" do
        subject.push_instruction(false)
        expect(subject.program).to be_empty
        expect(subject.prefixes).to eq [:a, :b, :c]

        subject.push_instruction(nil)
        expect(subject.program).to be_empty
        expect(subject.prefixes).to eq [:a, :b, :c]
      end

      it "pushes the given instruction onto the program" do
        subject.push_instruction(1)
        subject.push_instruction(2)
        subject.push_instruction(3)

        expect(subject.program).to be == [1, 2, 3]
      end

      it "pushes each element individually if the parameter is an array" do
        subject.push_instruction([1, 2])
        subject.push_instruction(3)
        subject.push_instruction([4, 5, 6])

        expect(subject.program).to be == [1, 2, 3, 4, 5, 6]
      end

      it "clears the prefix stack" do
        subject.push_instruction(:foo)

        expect(subject.prefixes).to be_empty
      end

      it "returns the index of the newly pushed instruction" do
        expect(subject.push_instruction(:foo)).to be 0
        expect(subject.push_instruction(:bar)).to be 1
        expect(subject.push_instruction(:baz)).to be 2
      end
    end

  end
end
