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

  describe "#" do
    it "returns the value of the data pointer (current position on the tape)" do
      @machine.tape[0] = 99

      run "#, >>>>> #,"

      expect(@machine.tape[0]).to be == 0
      expect(@machine.tape[5]).to be == 5
    end
  end

  describe "z" do
    it "returns 1 if the current cell is zero, 0 if not" do
      @machine.tape = [1, 0]

      run "z, > z,"

      expect(@machine.tape[0..1]).to be == [0, 1]
    end
  end

  describe "p" do
    it "returns the parity bit of the current cell" do
      @machine.tape = [13, 42]

      run "p, > p,"

      expect(@machine.tape[0]).to be == 1
      expect(@machine.tape[1]).to be == 0
    end
  end

  describe "r" do
    it "returns a random integer" do
      srand 999 # Make sure rand returns the same each time for testing purposes

      run "r+"

      expect(@machine.cell).to be == 192
    end
  end

end
