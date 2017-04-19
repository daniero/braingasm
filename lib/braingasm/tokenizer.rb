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
          y << read_token(scanner)
        end
      end
    end

    private
    def read_token(scanner)
      return scanner.matched.to_i if scanner.scan(/\d+/)
      @@simple_tokens[scanner.scan(/\S/)] || :unknown
    end

    @@simple_tokens = { '+' => :plus,
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
                        'Q' => :quit,
                        '[' => :loop_start,
                        ']' => :loop_end }

  end
end

