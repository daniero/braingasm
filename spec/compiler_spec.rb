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

    describe "#push_prefix" do
      it "pushes the given prefix to the prefix stack" do
        subject.push_prefix 1
        subject.push_prefix 2
        subject.push_prefix 3

        expect(subject.prefixes).to be == [1, 2, 3]
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
        let(:given_parameter) { 17 }
        let(:response) { subject.loop_start(given_parameter) }

        context "without prefix" do

          it "returns a loop with the given start index" do
            expect(response).to be_a Compiler::Loop
            expect(response.start_index).to be given_parameter
          end

          it "pushes the loop to the loop stack" do
            expect(subject.loop_stack).to be == [response]
          end
        end

        context "with number prefix" do
          before(:each) { subject.prefixes << 100 }

          it "returns two instructions" do
            expect(response).to be_an Array
            expect(response.size).to be 2
          end

          describe "first instruction" do
            it "calls machine's #inst_push_ctrl with the prefix" do
              expect(machine).to receive(:inst_push_ctrl).with(100)

              response.first.call(machine)
            end
          end

          describe "second instruction" do
            it "is a fixed loop with correct start index" do
              expect(response.last).to be_a Compiler::Loop
              expect(response.last.start_index).to be(given_parameter + 1)
            end

            it "is pushed to the loop stack" do
              expect(subject.loop_stack).to be == [response.last]
            end
          end
        end
      end

      describe "#loop_end" do
        let(:current_loop) { Compiler::Loop.new }

        before do
          subject.loop_stack = [current_loop]
        end

        it "fails if there is no loop object on the loop stack" do
          subject.loop_stack = []

          expect { subject.loop_end(:foo) }.to raise_error(BraingasmError)
        end

        it "returns a jump instruction back to the start of the current loop" do
          current_loop.start_index = 42
          expect(subject).to receive(:jump).with(42).and_return("jump_return_value")

          expect(subject.loop_end(:foo)).to eq("jump_return_value")
        end

        it "sets the stop_index to the given parameter" do
          subject.loop_end(13)

          expect(current_loop.stop_index).to be 13
        end

        it "pops the current loop off the loop stack" do
          subject.loop_end(:foo)

          expect(subject.loop_stack).to be_empty
        end
      end

      shared_examples "instruction prefix" do |method_name|
        it "pushes the generated instruction to the prefix stack" do
          method = subject.method(method_name)

          generated_instruction = method.call()

          expect(subject.prefixes).to be == Array(generated_instruction)
        end
      end

      describe "#pos" do
        include_examples "simple instruction", :pos, :pos
        include_examples "instruction prefix", :pos
      end

      describe "#random" do
        let(:generated_proc) { subject.random() }

        it "returns a proc returning a random number from 0 to the current cell max value" do
          Options[:cell_limit] = 100
          expect(subject).to receive(:rand).with(100).and_return(52)
          expect(generated_proc.call(machine)).to be(52)

          Options[:cell_limit] = 256
          expect(subject).to receive(:rand).with(256).and_return(18)
          expect(generated_proc.call(machine)).to be(18)
        end

        it "can take a prefix for max value" do
          subject.prefixes << 3000

          expect(subject).to receive(:rand).with(3000).and_return(7)
          expect(generated_proc.call(machine)).to be(7)
          expect(subject.prefixes).to be == Array(generated_proc)
        end

        include_examples "instruction prefix", :random
      end

    end

  end
end
