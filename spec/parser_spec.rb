# encoding: UTF-8
require 'spec_helper'
require "braingasm/compiler"

module Braingasm
  describe Parser do
    let(:compiler) { instance_double(Compiler) }
    subject { Parser.new(@input, compiler) }

    it "initializes all necessary fields" do
      @input = :something

      expect(subject.input).to be :something
      expect(subject.program).to be_an Array
      expect(subject.program).to be_empty
    end

    def provide_input(*tokens)
      tokenizer = instance_double(Tokenizer)
      enum = tokens.to_enum
      allow(tokenizer).to receive(:next) { enum.next }
      @input = tokenizer
    end

    describe "#parse_program" do
      before do
        provide_input(*[]) # I.e, no input
        allow(compiler).to receive(:loop_stack).and_return [] 
      end

      it "returns an empty program for empty input" do
        expect(subject.parse_program).to be == []
      end

      it "calls #parse_next with the tokenizer input until it raises StopIteration" do
        tokenizer = provide_input :foo
        expect(subject).to receive(:parse_next).with(tokenizer).and_raise(StopIteration)

        subject.parse_program
      end

      it "pushes each instruction returned by #parse_next individually with #push_instruction" do
        @input = [1, 2, 3].to_enum
        allow(subject).to receive(:parse_next).with(@input) { |arg| arg.next * 10 }
        expect(subject).to receive(:push_instruction).with(10).ordered
        expect(subject).to receive(:push_instruction).with(20).ordered
        expect(subject).to receive(:push_instruction).with(30).ordered

        subject.parse_program
      end

      it "ignores unknown tokens in the input" do
        provide_input(:unknown, :foo, :bar)

        expect(subject.parse_program).to be == []
      end

      it "fails if there are unclosed loops in the input" do
        expect(compiler).to receive(:loop_stack).and_return Array(:something)
        expect(subject).to receive(:raise_parsing_error).with(any_args)

        subject.parse_program
      end
    end

    describe "#parse_next" do
      subject { Parser.new(nil, compiler) }

      it "raises StopIteration on end of input" do
        empty = [].to_enum

        expect { subject.parse_next(empty) }.to raise_error StopIteration
      end

    end

    describe "#push_instruction" do
      it "does nothing if the parameter is falsy" do
        subject.push_instruction(false)
        expect(subject.program).to be_empty

        subject.push_instruction(nil)
        expect(subject.program).to be_empty
      end

      it "pushes the given instruction onto the program" do
        subject.push_instruction(1)
        subject.push_instruction(2)
        subject.push_instruction(3)

        expect(subject.program).to be == [1, 2, 3]
      end

      it "pushes each element individually if the parameter is an array" do
        subject.push_instruction([1, 2])
        subject.push_instruction(3)
        subject.push_instruction([4, 5, 6])

        expect(subject.program).to be == [1, 2, 3, 4, 5, 6]
      end

      it "returns the index of the newly pushed instruction" do
        expect(subject.push_instruction(:foo)).to be 0
        expect(subject.push_instruction(:bar)).to be 1
        expect(subject.push_instruction(:baz)).to be 2
      end
    end

    describe "#raise_parsing_error" do
      it "raises a ParsingError with the correct line and column numbers" do
        tokenizer = provide_input :foo
        expect(tokenizer).not_to be nil
        expect(tokenizer).to receive(:line_numer).and_return 100
        expect(tokenizer).to receive(:column_number).and_return 200
        error = nil

        expect { subject.raise_parsing_error("foobar") }.to raise_error(ParsingError) { |e| error = e }
        expect(error.line).to be 100
        expect(error.column).to be 200
      end
    end
  end

end
