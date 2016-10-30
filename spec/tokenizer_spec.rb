require 'spec_helper'
require "braingasm/tokenizer"

module Braingasm
  describe Tokenizer do
    subject { Tokenizer.new(@input) }
      it "is an enumerator over all non-whitespace characters in the input" do
        @input = "abc _\t\n+-<> "

        8.times { subject.next } # 8 none-whitespace characters in input
        expect { subject.next }.to raise_error StopIteration
      end

      it "handles empty input" do
        @input = ""

        expect { subject.next }.to raise_error StopIteration
      end

      describe "#next" do
        tokens = { '+' => :plus,
                   '-' => :minus,
                   '*' => :asterisk,
                   '/' => :slash,
                   '<' => :left,
                   '>' => :right,
                   '.' => :period,
                   ':' => :colon,
                   ',' => :comma,
                   ';' => :semicolon,
                   'C' => :C,
                   '#' => :hash,
                   'r' => :r,
                   'p' => :p,
                   'z' => :z,
                   's' => :s,
                   '[' => :loop_start,
                   ']' => :loop_end }

        tokens.each do |char, token|
          it "returns :#{token} when input is '#{char}'" do
            @input = char

            expect(subject.next).to eq(token)
          end
        end

        it "returns Integer objects when encountering numbers" do
          @input = "1 23+456"

          expect(subject.next).to be 1
          expect(subject.next).to be 23
          expect(subject.next).to be :plus
          expect(subject.next).to be 456
        end

        it "returns :unknown for any other input" do
          @input = "^?`)"

          4.times { expect(subject.next).to be :unknown }
        end
      end

      describe "#line_numer" do
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

        it "is not changed if tokenizer must read more after last valid token" do
          @input = "x\n"

          subject.next
          expect(subject.line_numer).to be 1
          expect { subject.next }.to raise_error StopIteration
          expect(subject.line_numer).to be 1
        end
      end

      describe "#column_number" do
        it "returns the column number from which the previous tokens was read" do
          @input = " a \nb c\n   d"

          subject.next
          expect(subject.column_number).to be 2
          subject.next
          expect(subject.column_number).to be 1
          subject.next
          expect(subject.column_number).to be 3
          subject.next
          expect(subject.column_number).to be 4
        end

        it "is not changed if tokenizer must read more after last valid token" do
          @input = "x "

          subject.next
          expect(subject.column_number).to be 1
          expect { subject.next }.to raise_error StopIteration
          expect(subject.column_number).to be 1
        end
      end
  end

end
