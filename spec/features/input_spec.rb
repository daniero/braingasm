require 'spec_helper'
require 'features/feature_helper'

describe "input methods" do
  include_context "braingasm features"

  before do
    @input = ''
    @machine.input = StringIO.new(@input, 'r')
  end

  describe "," do
    context "without prefix" do
      it "reads one byte from input and stores it in current cell" do
        @input << "hey"
        expect(@machine.tape).to all(be 0)

        run ","

        expect(@machine.cell).to be == 'h'.ord
        expect(@machine.tape.drop(1)).to all(be 0)
      end
    end

    context "with integer prefix" do
      it "stores given integer in current cell" do
        run "65,"

        expect(@machine.cell).to be == 65
      end
    end

    context "with string prefix" do
      it "stores its bytes on the tape, starting at the data pointer" do
        @machine.tape = [*0..9]
        @machine.dp = 4

        run '"ABC",'

        expect(@machine.tape).to be == [0, 1, 2, 3, 65, 66, 67, 7, 8, 9]
      end

      it "expands the tape if necessary" do
        @machine.tape = [0, 0, 0]

        run '"ABCDEF",'

        expect(@machine.tape).to be == [65, 66, 67, 68, 69, 70]
      end

      it "wraps around if tape limit is set" do
        run '6L 3> "ABCDE",'

        expect(@machine.tape[0..5]).to be == [68, 69, 0, 65, 66, 67]
        expect(@machine.tape[6]).to be == 0
      end
    end
  end

  describe ";" do
    it "reads an integer from input and stores it in current cell" do
      @input << "123"

      run ";"

      expect(@machine.cell).to be == 123
    end

    it "takes an optional integer parameter and uses it as input radix" do
      @input << "100"

      run "2;"

      expect(@machine.cell).to be == 4
    end

    it "scans past trailing whitespace" do
      @input << "   \t  8"

      run ";"

      expect(@machine.cell).to be == 8
    end

    it "leaves cell unchanged if no input reaches end of line without hitting an integer" do
      @machine.cell = 1
      @input << "  \t  \n"

      run ";"

      expect(@machine.cell).to be == 1
    end

    it "reads next integer from next line of input" do
      @input << "  \t  \n 88"

      run ";;"

      expect(@machine.cell).to be == 88
    end
  end
end

