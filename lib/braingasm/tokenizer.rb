require 'strscan'

module Braingasm
  class Tokenizer < Enumerator
    attr_accessor :input
    attr_reader :line_numer

    def initialize(input)
      @line_numer = 1

      scanner = StringScanner.new(input)

      super() do |y|
        loop do
          while scanner.skip(/\s/)
            @line_numer += 1 if scanner.beginning_of_line?
          end

          break if scanner.eos?
          y << scanner.scan(/\S/)
        end
      end
    end
  end
end

