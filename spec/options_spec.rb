require 'spec_helper'
require "braingasm/options"

module Braingasm
  describe :handle_options do
    it "translates command line options to Braingasm options" do
      Braingasm.handle_options(:zero => true)
      expect(Options[:eof]).to be 0

      Braingasm.handle_options(:negative => true)
      expect(Options[:eof]).to be -1

      Braingasm.handle_options(:as_is => true)
      expect(Options[:eof]).to be nil
    end
  end
end
