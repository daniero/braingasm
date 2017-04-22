require 'spec_helper'
require 'features/feature_helper'

describe "braingasm language" do
  include_context "braingasm"

  describe "basic instructions" do
    describe ">" do
      before do
        @machine.tape = [21, 42]
        expect(@machine.dp).to be == 0
        expect(@machine.cell).to be == 21
      end

      it "increases the data pointer, moving to the next cell" do
        run ">"

        expect(@machine.dp).to be == 1
        expect(@machine.cell).to be == 42
      end

      it "takes an optional integer parameter and moves by that much" do
        run "7>"

        expect(@machine.dp).to be == 7
        expect(@machine.cell).to be == 0
      end
    end

    describe "<" do
      before do
        @machine.tape = [1, 2, 4, 8, 16, 32]
        @machine.dp = 5
        expect(@machine.cell).to be == 32
      end

      it "decreases the data pointer, moving to the previous cell" do
        run "<"

        expect(@machine.dp).to be == 4
        expect(@machine.cell).to be == 16
      end

      it "takes an optional integer parameter and moves by that much" do
        run "3<"

        expect(@machine.dp).to be == 2
      end
    end

    describe "+" do
      it "increases the value of current cell by one" do
        run "+"

        expect(@machine.cell).to be == 1
      end

      it "takes an optional integer parameter and increases by that much" do
        run "42+"

        expect(@machine.cell).to be == 42
      end
    end

    describe "-" do
      it "decreases the value of the current cell by one" do
        @machine.cell = 100

        run "-"

        expect(@machine.cell).to be == 99
      end

      it "takes an optional integer parameter and decreases by that much" do
        @machine.cell = 123

        run "23-"

        expect(@machine.cell).to be == 100
      end
    end

    describe "*" do
      it "multiplies the value of the current cell by two" do
        @machine.cell = 9

        run "*"

        expect(@machine.cell).to be == 18
      end

      it "takes an optional integer parameter and multiplies with that much" do
        @machine.cell = 3

        run "5*"

        expect(@machine.cell).to be == 15
      end
    end

    describe "/" do
      it "divides the value of the current cell by two" do
        @machine.cell = 100

        run "/"

        expect(@machine.cell).to be == 50
      end

      it "takes an optional integer parameter and divides by that much" do
        @machine.cell = 60

        run "12/"

        expect(@machine.cell).to be == 5
      end
    end
  end
end
