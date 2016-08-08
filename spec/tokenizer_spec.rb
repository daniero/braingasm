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

      it "handles empty input" do
        @input = ""

        expect { subject.next }.to raise_error StopIteration
      end

      describe :line_numer do
        it "returns the line number from which the previous token was read" do
          @input = " a \nbc\n d"

          subject.next
          expect(subject.line_numer).to be 1
          subject.next
          expect(subject.line_numer).to be 2
          subject.next
          expect(subject.line_numer).to be 2
          subject.next
          expect(subject.line_numer).to be 3
        end
      end
  end

end
