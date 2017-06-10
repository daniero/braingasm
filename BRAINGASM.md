# Braingasm documentation

Work in progress!

TODO: Some nice intro here.

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

## Prefixes

TODO: Short something about prefixes in general here.

### `z`: Zero

Returns `1` if the current cell or given parameter is `0`, otherwise returns 
`0`.

### `n`: Non-zero

Opposite of `z`.
