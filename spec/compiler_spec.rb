module Braingasm
  describe Compiler do
    it { should have_attributes(:prefixes => [], :loop_stack => []) }

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
      end
    end

  end
end
