module Braingasm
  class Tokenizer < Enumerator
    attr_accessor :input

    def initialize(input)
      super() do |y|
        input.scan(/\S/) { |token| y << token }
      end
    end
  end
end

