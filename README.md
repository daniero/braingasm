# Braingasm

Braingasm is a super-set of [brainfuck](https://esolangs.org/wiki/brainfuck), 
and extends the 8 original instructions with a few new ones, along with the 
concept of *prefixes* and *registers*.

The original idea for the language was to combine *brainfuck* and assembly code 
(*asm*), hence the name.

braingasm is still under development and breaking changes may occur.

### Sample code

Here's an implementation of the famous FizzBuzz program written in braingasm:

    100[>#3p["Fizz".+]#5p["Buzz".+]z[#:]10.]

It works like this:

    100[               One hundred times:
        >                Go to the next cell.
        #3p[             If current cell number is divisble by 3:
            "Fizz".        Print "Fizz".
            +              Increment current cell
        ]
        #5p["Buzz".+]    Same thing for 5 and "Buzz".
        z[               If the current cell is 0 (hasn't been incremented):
          #:               Print current cell number
        ]
        10.              Print a newline
    ]

### The language
As plain brainfuck, braingasm is a simple language that operates on an 
arbitrarily long *tape*. The tape is continuous array of *cells* which hold an 
integer value. In braingasm the cells may by default hold arbitrarily large 
values, both positive and negative. All cells are initially zero. The tape is 
the only form of storage available to the programmer -- there is no concept of 
variables.

Instructions usually consist of one character and alter the cell under the *data 
pointer*. The cell under the data pointer is known as the *current* cell.

### Instructions
`<` and `>` moves the data pointer one step to the left or right respectively. 
`+` increments the value of the current cell by one, while `-` decrements it.
Input is done with `,` (read one byte from stdin to the current cell) and `;` 
(read a number), and output with `.` (print current cell as a byte) and `:` 
(print as number). Code enclosed in square brackets (`[` and `]`) will be 
repeated as long as the value of the current cell is not zero.

For the full list of instructions and more details about their behaviour, see 
the [docs](BRAINGASM.md#instructions) or the 
[specs](spec/features/instructions_spec.rb).

### Prefixes
A prefix may alter the effect of an instruction in different ways. The simplest 
kind of prefix is a numeric literal, which makes the succeeding instruction 
repeat a certain number of times:

* `5+` increases the value of the current cell by 5.
* `7[X]` Runs the loop, containing some code `X`, exactly 7 times.

Most prefixes are dependent on the value of the current cell:

* The `z` prefix evaluates as `1` if the current cell holds the value `0`, 
  otherwise it returns `0`.
* The `#` register holds the current position in the data tape. `#>` will move 
  to cell 12 if the current cell is 6, while `#<` always will return to the 
  original start position on the tape.

Some prefixes can take prefixes themselves:

* The parity prefix, `p`, alone returns `1` or `0` depending on whether the 
  value of the current cell is even.
* If given an integer literal, `p` will rather check the parity in that "base": 
  `3p:` will print `1` if the current data pointer is divisible by 3, or `0` 
  otherwise.
* If given another prefix which returns an integer, `p` will evaluate the result 
  of that prefix instead: `#p:` will print `1` if the current data pointer is an 
  even number.
* Given two integers, `p` checks if the first integer is divisible by the second.


More information about the different prefixes can be found in the 
[docs](BRAINGASM.md#prefixes) or [specs](spec/features/prefixes_spec.rb).

## Installation

You need [Ruby](https://www.ruby-lang.org/) in order to run braingasm. Install 
braingasm from the command line with:

    $ gem install braingasm

## Usage

    $ braingasm my_program.bg

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at 
https://github.com/daniero/braingasm.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

