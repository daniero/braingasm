# Braingasm documentation

Work in progress!

TODO: some nice intro here.

## Instructions

TODO: Short something about instructions in general here.

### `+`: Increment

Increments the value of the current cell by one, or the given amount:

* If the current cell is `2`, then
    * `+` will make it become `5`.
    * `5+` will make it `7`.
    * `z+` will do nothing, because [`z`](#z-zero) evaluates to `0`.

### `-`: Decrement

Exactly like `+`, only decrementing instead of incrementing.

### `*`: Double/Multiply

Without a prefix, doubles the value of the current cell.
With an integer prefix, multiplies the current cell by that much.

### `/`: Half/divide

Divides the current cell by two, or by the given amount.

### `>`: Move right

Moves one step to the right (to the next cell), or if an integer prefix is
given, moves that many cells to the right.

### `<`: Move left

Moves one step to the left (to the previous cell), or if an integer prefix is
given, moves that many cells to the left.

### `Q`: Quit

Without prefix, simply quits the program. If given an integer, it quits the
program *unless* the integer is `0`.

## Prefixes

TODO: Short something about prefixes in general here.

### `$`: Cell value

Returns the value of the current cell. If given an integer prefix, it returns
the value of the cell with the given index of the tape.

### `#`: Data pointer / tape position

Returns the current position on the tape, relative to its start position.

### `z`: Zero

Returns `1` if the current cell or given parameter is `0`, otherwise returns 
`0`.

### `n`: Non-zero

Opposite of `z`.

### `q`: Prime

Returns `1` if the current cell or given parameter is a prime, otherwise returns
`0`.
