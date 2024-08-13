# Super Mario 64 custom assembly code for ROM hacks

These assembly programs can be inserted into a Super Mario 64 US ROM using the
[Simple Armips GUI][armips]. Many comments are present in the assembly files to
help understanding and allow for modifications, do not hesitate to take a read.

[armips]: https://github.com/DavidSM64/SimpleArmipsGui/releases

## Quality of Life

- `fix_steep_jump`: Make non-slippery surfaces not trigger steep jumps when
  facing uphill.
- `cap_timer`: Display the time remaining before cap expiration.

## Custom Mechanics

- `double_jump`: Code for a midair double jump, and a crystal that gives you
  back your ability midair (Celeste style)
- `firsty_wall`: A custom wall type that always gives a firsty when wallkicked,
  no matter the frame (collision ID `2`).
- `wide_wallkick_wall`: A custom wall type that can be wallkicked from any
  angle (collision ID `3`).
