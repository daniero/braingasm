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
      if scanner.scan(/\d+/)
        scanner.matched.to_i
      elsif scanner.scan(/"/)
        s = scanner.scan(/[^"]*/)
        scanner.skip(/"/)
        s
      else
        @@simple_tokens[scanner.scan(/\S/)] || :unknown
      end
    end

    @@simple_tokens = { '+' => :increment,
                        '-' => :decrement,
                        '*' => :multiply,
                        '/' => :divide,
                        '<' => :left,
                        '>' => :right,
                        '.' => :print,
                        ':' => :output,
                        ',' => :read,
                        ';' => :input,
                        '$' => :value,
                        '#' => :position,
                        'r' => :random,
                        'p' => :parity,
                        'o' => :oddity,
                        'z' => :zero,
                        's' => :signed,
                        'C' => :compare,
                        'Q' => :quit,
                        'L' => :tape_limit,
                        '[' => :loop_start,
                        ']' => :loop_end }

  end
end

