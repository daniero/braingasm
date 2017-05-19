require 'spec_helper'
require 'features/feature_helper'

describe "basic instructions" do
  include_context "braingasm features"

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

    it "can move beyond the current end of the tape" do
      @machine.tape = []

      run "99>"

      expect(@machine.dp).to be == 99
    end
  end

  describe "<" do
    it "decreases the data pointer, moving to the previous cell" do
      @machine.tape = [1, 2, 4, 8, 16, 32]
      @machine.dp = 5
      expect(@machine.cell).to be == 32

      run "<"

      expect(@machine.dp).to be == 4
      expect(@machine.cell).to be == 16
    end

    it "takes an optional integer parameter and moves by that much" do
      @machine.dp = 10

      run "3<"

      expect(@machine.dp).to be == 7
    end

    it "can move past the current start of the tape" do
      run "99<"
    end

    context "with # prefix" do
      it "moves back to original start of tape" do
        run "99>#<"

        expect(@machine.dp).to be == 0
      end

      it "moves back to original start of tape also from the left" do
        @machine.cell = 13

        run "7<+#<"

        expect(@machine.cell).to be == 13
      end
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

describe "tape limit (L instruction)" do
  include_context "braingasm features"

  describe "without a prefix" do
    it "makes the tape wrap around after the current position" do
      run "17+ 5> L >"

      expect(@machine.dp).to be == 0
      expect(@machine.cell).to be == 17
    end

    describe "from a negative position" do
      it "wraps around to start position when going further left" do
        run "7+ 5< L <"

        expect(@machine.pos).to be == 0
        expect(@machine.cell).to be == 7
      end

      it "stays within negative indices" do
        run "5< L 2<"

        expect(@machine.pos).to be == -1
      end

      it "can reach the start position moving right" do
        run "5< L 5>"

        expect(@machine.pos).to be == 0
      end

      it "wraps around when moving to the right past start position" do
        run "5< L 6>"

        expect(@machine.pos).to be == -5
      end
    end
  end

  describe "given an integer prefix" do
    it "limits the tape to that length" do
      run "5L 12[+>]"

      expect(@machine.tape.take(5)).to be == [3, 3, 2, 2, 2]
      expect(@machine.tape.drop(5)).to all (be 0)
    end

    it "makes the tape wrap back to the last cell when moving left from start position" do
      run "9L <"

      expect(@machine.dp).to be == 8
    end
  end
end
