require 'spec_helper'
require 'features/feature_helper'

describe "output methods" do
  include_context "braingasm features"

  before do
    @output = ''
    @machine.output = StringIO.new(@output, 'w')
  end

  describe "." do
    context "without prefix" do
      it "prints the current cell as a byte value" do
        @machine.tape[0] = 65

        run "."

        expect(@output).to be == "A"
      end

      it "prints large values as multiple bytes" do
        run "6841721,."

        expect(@output).to be == "hey"
      end
    end

    context "with integer prefix" do
      it "prints its byte value" do
        run "66."

        expect(@output).to be == "B"
      end

      it "prints large values as multiple bytes" do
        run "6841721."

        expect(@output).to be == "hey"
      end
    end

    context "with string prefix" do
      it "prints it" do
        run %{"Hey".}

        expect(@output).to be == "Hey"
      end
    end
  end

  describe ":" do
    it "prints the current cell as an integer string" do
      @machine.tape[0] = 65

      run ":"

      expect(@output).to be == "65"
    end

    it "takes an optional integer parameter and prints that instead" do
      run "72:"

      expect(@output).to be == "72"
    end
  end
end
