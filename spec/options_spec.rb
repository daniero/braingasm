require 'spec_helper'
require "braingasm/options"

module Braingasm
  describe "#handle_options" do
    it "translates command line options to Braingasm options" do
      Braingasm.handle_options(:zero => true)
      expect(Options[:eof]).to be 0

      Braingasm.handle_options(:negative => true)
      expect(Options[:eof]).to be (-1)

      Braingasm.handle_options(:as_is => true)
      expect(Options[:eof]).to be nil

      expect(Options[:wrap_cells]).to be true
      Braingasm.handle_options(:wrap_cells => true)
      expect(Options[:wrap_cells]).to be true
    end

    context "when :cell_size is given" do
      let(:opts) { {:cell_size_given => true} }

      it "sets :cell_limit to an integer with :cell_size number of bits" do
        Braingasm.handle_options(**opts, :cell_size => 8)
        expect(Options[:cell_limit]).to be 256

        Braingasm.handle_options(**opts, :cell_size => 1)
        expect(Options[:cell_limit]).to be 2

        Braingasm.handle_options(**opts, :cell_size => 32)
        expect(Options[:cell_limit]).to be 4294967296
      end
    end
  end
end
