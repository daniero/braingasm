module Braingasm

  describe PrefixStack do

    describe "#fix_params" do
      let(:input_function) { instance_double(Proc) }
      let(:machine) { instance_double(Machine) }

      describe "currying input functions with simple prefixes" do
        let(:curried_function) { instance_double(Proc) }
        before { expect(input_function).to receive(:curry).and_return(curried_function) }

        context "when prefix stack is empty" do
          it "curries the given function with the default value, 1" do
            expect(curried_function).to receive(:call).with(1)

            subject.fix_params(input_function)
          end

          it "curries the given function with the given integer, if provided" do
            expect(curried_function).to receive(:call).with(14)

            subject.fix_params(input_function, 14)
          end
        end

        context "with an integer on the prefix stack" do
          let(:curried_function) { instance_double(Proc) }
          before { subject.stack << 1234 }

          it "curries the given function with the integer on the stack" do
            expect(curried_function).to receive(:call).with(1234)

            subject.fix_params(input_function)
          end
        end
      end


      context "with a function on the prefix stack" do
        let(:machine) { double() }
        let(:prefix_function) { proc { |m| m.some_instruction() } }
        before { subject.stack << prefix_function }

        it "chains the output of prefix function into the given function" do
          expect(machine).to receive(:some_instruction).and_return(:foo)
          expect(input_function).to receive(:call).with(:foo, machine)

          chained_function = subject.fix_params(input_function)
          chained_function.call(machine)
        end
      end

      after { expect(subject.stack).to be_empty }
    end

  end
end
