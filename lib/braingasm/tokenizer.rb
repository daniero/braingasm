require 'strscan'

module Braingasm
  class Tokenizer < Enumerator
    attr_accessor :input
    attr_reader :line_numer, :column_number

    def initialize(input)
      @line_numer = 1
      @column_number = 0

      scanner = StringScanner.new(input)

      super() do |y|
        loop do
          line_numer, column_number = @line_numer, @column_number

          while scanner.skip(/\s/)
            if scanner.beginning_of_line?
              line_numer += 1
              column_number = 0
            else
              column_number += 1
            end
          end

          break if scanner.eos?

          column_number += 1
          @line_numer, @column_number = line_numer, column_number
          y << scanner.scan(/\S/)
        end
      end
    end
  end
end

