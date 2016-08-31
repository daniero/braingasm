module Braingasm
  describe Compiler do
    it { should have_attributes(:prefixes => [], :loop_stack => []) }

    let(:machine) { instance_double(Machine) }

    describe "#fix_params" do
      let(:function) { instance_double(Proc) }

      context "with single integer prefixes" do
        let(:curried_function) { instance_double(Proc) }
        before(:each) { expect(function).to receive(:curry).and_return(curried_function) }

        context "when prefix stack is empty" do
          it "curries the given function with the default value, 1" do
            expect(curried_function).to receive(:call).with(1)

            subject.fix_params(function)
          end

          it "curries the given function with the given integer, if provided" do
            expect(curried_function).to receive(:call).with(14)

            subject.fix_params(function, 14)
          end
        end

        context "with an integer on the prefix stack" do
          before { subject.prefixes << 1234 }

          it "curries the given function with the prefix" do
            expect(curried_function).to receive(:call).with(1234)

            subject.fix_params(function)
          end

          after(:each) { expect(subject.prefixes).to be_empty }
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

  end
end
