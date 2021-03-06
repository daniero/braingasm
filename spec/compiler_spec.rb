module Braingasm
  describe Compiler do
    let(:machine) { instance_double(Machine) }
    let(:prefix_stack) { instance_double(PrefixStack) }
    before { subject.prefixes = prefix_stack }

    describe "#push_prefix" do
      it "pushes the given prefix to the prefix stack" do
        expect(prefix_stack).to receive(:<<).with(:foo)

        subject.push_prefix(:foo)
      end
    end

    shared_examples "simple instruction generation" do |method_name, machine_instruction|
      context "without prefix" do
        before { allow(prefix_stack).to receive(:empty?).and_return(true) }

        it "generates a function which calls the machine's ##{machine_instruction}" do
          expect(machine).to receive(machine_instruction).with(no_args)

          generated_instruction = subject.method(method_name).call()

          generated_instruction.call(machine)
        end
      end
    end

    shared_examples "prefixed instruction" do |method_name, machine_instruction|
      context "with prefix" do
        before { allow(prefix_stack).to receive(:empty?).and_return(false) }

        it "sends a function to PrefixStack to inject the proper parameters" do
          expect(prefix_stack).to receive(:fix_params) { |generated_function|
            expect(machine).to receive(machine_instruction).with("some parameter")
            generated_function.call("some parameter", machine)
          }

          subject.method(method_name).call()
        end

        it "returns the transformed function from the prefix stack" do
          expect(prefix_stack).to receive(:fix_params).and_return "return value"

          expect(subject.method(method_name).call()).to be == "return value"
        end

        describe "generated instruction" do
          let(:prefix) { 42 }
          let(:prefix_stack) { PrefixStack.new }
          before { prefix_stack << prefix }
          let(:generated_instruction) { subject.method(method_name).call }

          it "calls the machine's ##{machine_instruction} with the prefix as parameter" do
            expect(machine).to receive(machine_instruction).with(prefix)

            generated_instruction.call(machine)
          end
        end
      end
    end

    describe "#inc" do
      include_examples "prefixed instruction", :inc, :inst_inc
    end

    describe "#dec" do
      include_examples "prefixed instruction", :dec, :inst_dec
    end

    describe "#multiply" do
      include_examples "prefixed instruction", :multiply, :inst_multiply
    end

    describe "#divide" do
      include_examples "prefixed instruction", :divide, :inst_divide
    end

    describe "#right" do
      include_examples "prefixed instruction", :right, :inst_right
    end

    describe "#left" do
      include_examples "prefixed instruction", :left, :inst_left
    end

    describe "#print" do
      include_examples "simple instruction generation", :print, :inst_print_cell
      include_examples "prefixed instruction", :print, :inst_print
    end

    describe "#print_int" do
      include_examples "simple instruction generation", :print_int, :inst_print_cell_int
      include_examples "prefixed instruction", :print_int, :inst_print_int
    end

    describe "#read_int" do
      include_examples "prefixed instruction", :read_int, :inst_read_int
    end

    describe "#compare" do
      include_examples "simple instruction generation", :compare, :inst_compare_cells
    end

    describe "#quit" do
      include_examples "simple instruction generation", :read, :inst_read_byte
      include_examples "prefixed instruction", :quit, :inst_quit
    end

    describe "#loop_start" do
      let(:prefix_stack) { PrefixStack.new }
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

    shared_examples "generated prefix" do |method_name|
      let(:prefix_stack) { PrefixStack.new }

      it "pushes the generated value to the prefix stack" do
        pushed_prefix = nil
        expect(prefix_stack).to receive(:<<) { |prefix| pushed_prefix = prefix }

        return_value = subject.method(method_name).call()
        expect(pushed_prefix).to be return_value
      end
    end

    describe "#pos" do
      include_examples "generated prefix", :pos
      include_examples "simple instruction generation", :pos, :pos
    end

  end
end
