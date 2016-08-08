require 'spec_helper'
require "braingasm/tokenizer"

module Braingasm
  describe Tokenizer do
    subject { Tokenizer.new(@input) }

      it "is an enumerator over all non-whitespace characters in the input" do
        @input = "abc _\t\n+-<> "

        expect(subject.next).to be == 'a'
        expect(subject.next).to be == 'b'
        expect(subject.next).to be == 'c'
        expect(subject.next).to be == '_'
        expect(subject.next).to be == '+'
        expect(subject.next).to be == '-'
        expect(subject.next).to be == '<'
        expect(subject.next).to be == '>'
        expect { subject.next }.to raise_error StopIteration
      end
  end

end
