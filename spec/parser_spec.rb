# encoding: UTF-8
require 'spec_helper'
require "braingasm/machine"

describe Braingasm::Parser do
  subject { Braingasm::Parser.new(@input) }

  describe :parse do
    it "returns an empty program for empty input" do
      @input = ""

      expect(subject.parse).to be == []
    end

    describe "simple instructions" do
      inputs = { '+' => :inc,
                 '-' => :dec,
                 '>' => :right,
                 '<' => :left,
                 '.' => :print,
                 ',' => :read }

      inputs.each do |input, instruction|
        it "pushes an instruction '#{instruction}' given a '#{input}'" do
          @input = input
          return_value = "#{instruction}_return"
          allow(subject).to receive(instruction).and_return(return_value)

          expect(subject.parse).to be == [return_value]
        end
      end

    end

  end
end
