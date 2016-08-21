# Braingasm

Braingasm is a super-set of [brainfuck](https://esolangs.org/wiki/brainfuck), 
and extends the 8 original instructions with the concept of *prefixes* and 
*registers*.

The original idea for the language was to combine brainfuck and assembly code 
(asm), hence the name.

### Prefixes
A prefix may alter the effect of an instruction in different ways. The simplest 
kind of prefix is a numeric literal, which makes the succeeding instruction 
repeat a certain number of times:

* `5+` increases the value of the current cell by 5.
* `7[X]` Runs the loop, containing some code `X`, exactly 7 times.

### Registers
Registers can also be used as prefixes. Registers are typically updated when 
other instructions are executed:

* The `z` register holds the value `1` if the previous update of a cell caused 
  it the reach the value 0. Otherwise the `z` register holds the value `0`.
* The `#` register holds the current position in the data tape. `#>` will move 
  to cell 12 if the current cell is 6.

More information about the different prefixes and registers will come.

## Installation

Install Braingasm from the command line with:

    $ gem install braingasm

Or to use it in your application, add this line to your Gemfile:

```ruby
gem 'braingasm'
```

And then execute:

    $ bundle

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

