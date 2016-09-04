module Braingasm

  describe PrefixStack do

    describe "#fix_params" do
      let(:input_function) { instance_double(Proc) }
      let(:curried_function) { instance_double(Proc) }
      before { expect(input_function).to receive(:curry).and_return(curried_function) }
      let(:machine) { instance_double(Machine) }

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
        before { subject.stack << 1234 }

        it "curries the given function with the integer on the stack" do
          expect(curried_function).to receive(:call).with(1234)

          subject.fix_params(input_function)
        end
      end

      after { expect(subject.stack).to be_empty }
    end

  end
end
