require 'spec_helper'
require 'features/feature_helper'

describe "braingasm language" do
  include_context "braingasm"

  describe "tape manupulation" do
    describe "'+' instruction" do
      it "increases the value of the current cell by one" do
        run "+"

        expect(@machine.cell).to be == 1
      end

      it "takes an optional integer parameter" do
        run "42+"

        expect(@machine.cell).to be == 42
      end
    end
  end
end
