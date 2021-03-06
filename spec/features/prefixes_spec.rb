require 'spec_helper'
require 'features/feature_helper'

describe "prefixes" do
  include_context "braingasm features"

  describe "numbers" do
    it "work as expected" do
      run "69+"

      expect(@machine.cell).to be == 69
    end
  end

  describe "$" do
    describe "without a prefix" do
      it "returns the value of the current cell" do
        @machine.cell = 21

        run "$+"

        expect(@machine.cell).to be == 42
      end

      it "returns negative values too" do
        @machine.cell = -5

        run "$+"

        expect(@machine.cell).to be == -10
      end
    end

    it "can be prefixed by itself" do
      @machine.tape = [3, 0, 0, 42]

      run "$$,"

      expect(@machine.cell).to be == 42
    end

    describe "given an integer" do
      it "returns the value of the cell in that position" do
        @machine.tape = [0, 0, 0, 99]

        run "3$+"

        expect(@machine.cell).to be == 99
      end

      it "works also when the tape is expanded backwards" do
        @machine.cell = 2

        run "6< 0$+ +"

        expect(@machine.pos).to be == -6
        expect(@machine.cell).to be == 3
        expect(@machine.tape[6]).to be == 2
      end

      it "works with negative indices" do
        run "<<<+++++>>> --- $$,"

        expect(@machine.cell).to be == 5
      end
    end
  end

  describe "#" do
    it "returns the value of the data pointer (current position on the tape)" do
      @machine.tape[0] = 99

      run "#, >>>>> #,"

      expect(@machine.tape[0]).to be == 0
      expect(@machine.tape[5]).to be == 5
    end

    it "returns a negative value if moving left from the starting position" do
      run "7< #,"

      expect(@machine.cell).to be == -7
    end

    it "always returns zero on the original tape position" do
      run "<<<+++>>> #,"

      expect(@machine.pos).to be == 0
      expect(@machine.cell).to be == 0
    end
  end

  describe "z" do
    context "without prefix" do
      it "returns 1 if the current cell is zero, 0 if not" do
        @machine.tape = [1, 0]

        run "z, > z,"

        expect(@machine.tape[0..1]).to be == [0, 1]
      end
    end

    context "with integer prefix" do
      it "checks the prefix instead" do
        run "1z, > 0z,"

        expect(@machine.tape[0..1]).to be == [0, 1]
      end
    end
  end

  describe "n" do
    context "without prefix" do
      it "returns 1 if the current cell is non-zero, 0 if its zero" do
        @machine.tape = [1, 0, -1]

        run "n+ > n+ > n+"

        expect(@machine.tape[0..2]).to be == [2, 0, 0]
      end
    end

    context "with integer prefix" do
      it "checks the prefix instead" do
        run "<#n+ >#n+ >#n+"

        expect(@machine.tape[0..2]).to be == [1, 0, 1]
      end
    end
  end

  describe "s" do
    context "without prefix" do
      it "returns 1 if the current cell is negative (signed), 0 otherwise" do
        @machine.tape = [-2, -1, 0, 1, 2]

        run "s, > s, > s, > s, > s,"

        expect(@machine.tape).to be == [1, 1, 0, 0, 0]
      end
    end

    context "with integer prefix" do
      it "returns 0 if the given prefix is zero or positive" do
        run "#s, > #s,"

        expect(@machine.tape[0..1]).to be == [0, 0]
      end

      it "returns 1 if the given prefix is negative" do
        run "< #s,"

        expect(@machine.cell).to be == 1
      end
    end
  end

  describe "p (parity)" do
    context "without prefix" do
      it "returns 1 if the value of the current cell is even, 0 if it's odd" do
        @machine.tape = [42, 13]

        run "p, > p,"

        expect(@machine.tape[0]).to be == 1
        expect(@machine.tape[1]).to be == 0
      end
    end

    context "with prefix yielding an integer" do
      it "evaulates the prefix instead" do
        run "4> #p, > #p,"

        expect(@machine.tape[4]).to be == 1
        expect(@machine.tape[5]).to be == 0
      end
    end

    context "with an integer literal prefix" do
      it "returns 1 if the current cell is divisble by the given integer, 0 otherwise" do
        @machine.tape = [0, 1, 2, 3]

        run "4[ 3p, > ]"

        expect(@machine.tape[0]).to be == 1
        expect(@machine.tape[1]).to be == 0
        expect(@machine.tape[2]).to be == 0
        expect(@machine.tape[3]).to be == 1
      end
    end

    context "with two integer prefixes, the second an integer literal" do
      it "checks the first, modulo the second" do
        run "7> #4p, > #4p,"

        expect(@machine.tape[7]).to be == 0
        expect(@machine.tape[8]).to be == 1
      end
    end

    context "with two integer prefixes" do
      it "checks the first, modulo the second" do
        run "6> 7#p, > 7#p,"

        expect(@machine.tape[6]).to be == 0
        expect(@machine.tape[7]).to be == 1
      end
    end
  end

  describe "o (oddity)" do
    context "without prefix" do
      it "returns 1 if the value of the current cell is odd, 0 if it's even" do
        @machine.tape = [42, 13]

        run "o, > o,"

        expect(@machine.tape[0]).to be == 0
        expect(@machine.tape[1]).to be == 1
      end
    end

    context "with prefix yielding an integer" do
      it "evaulates the prefix instead" do
        run "7> #o, > #o,"

        expect(@machine.tape[7]).to be == 1
        expect(@machine.tape[8]).to be == 0
      end
    end

    context "with an integer literal prefix" do
      it "returns 0 if the current cell is divisble by the given integer, 1 otherwise" do
        @machine.tape = [0, 1, 2, 3]

        run "4[ 3o, > ]"

        expect(@machine.tape[0]).to be == 0
        expect(@machine.tape[1]).to be == 1
        expect(@machine.tape[2]).to be == 1
        expect(@machine.tape[3]).to be == 0
      end
    end

    context "with two integer prefixes, the second an integer literal" do
      it "checks the first, modulo the second" do
        run "3> #4o, > #4o,"

        expect(@machine.tape[3]).to be == 1
        expect(@machine.tape[4]).to be == 0
      end
    end

    context "with two integer prefixes" do
      it "checks the first, modulo the second" do
        run "6> 7#o, > 7#o,"

        expect(@machine.tape[6]).to be == 1
        expect(@machine.tape[7]).to be == 0
      end
    end
  end

  describe "q" do
    context "without prefix" do
      it "checks if the current cell value is a prime" do
        @machine.tape = [ 2, 4, 7 ]

        run "q, > q, > q,"

        expect(@machine.tape).to be == [ 1, 0, 1 ]
      end
    end

    context "given an integer" do
      it "checks if it's s a prime" do
        run "7q+ > 9q+"

        expect(@machine.tape[0..1]).to be == [ 1, 0 ]
      end
    end
  end

  describe "r" do
    context "without prefix" do
      it "returns a random integer between 0 inclusive and 256 exclusive" do
        srand 999 # Seed the RNG to make sure we get the same each time, for testing purposes

        run "r+ > r+ > r+"

        expect(@machine.tape[0]).to be == 192
        expect(@machine.tape[1]).to be == 92
        expect(@machine.tape[2]).to be == 101
      end
    end

    context "with one integer prefix" do
      it "returns a random integer below that number" do
        run "100[ 3r+ > ]"

        expect(@machine.tape).to all(be < 3)
        expect(@machine.tape).to include(0)
        expect(@machine.tape).to include(1)
        expect(@machine.tape).to include(2)
      end

      it "works with non-literal integers too" do
        srand 3

        run "50> #r+"

        expect(@machine.cell).to be == 42
      end
    end

    context "with two integer prefixes" do
      it "returns a random integer between 0 and that number" do
        run "999[ 2 5r+ > ]"

        expect(@machine.tape[0...100]).to all(be >= 2)
        expect(@machine.tape[0...100]).to all(be <= 5)
        expect(@machine.tape).to include(2)
        expect(@machine.tape).to include(5)
      end

      it "works with non-literal integers too" do
        srand 100

        run "25> 3#r+"

        expect(@machine.cell).to be == 11
      end
    end
  end

end
