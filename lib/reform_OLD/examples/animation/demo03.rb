
# Copyright (c) 2010 Eugene Brazwick

=begin
  This example shows a basic statemachine in action.

  We tie the operation of the state to
    1) what triggers them
    2) which property they affect

  This is diametral to Qt's system which stores these things with the states themselves.


=end
require 'reform/app'

Reform::app {
  statemachine {
#     name :myStatemachine
    states :s1, :s2, :s3
  }
  button {
    text tr('Click Me')
    # in a later version the keyword 'transition:' may be skipped to get:
    # whenClicked s1: :s2, s2: :s3, s3: :s1.
    # But it depends on how 'whenClicked' will evolve
    whenClicked transition: { s1: :s2, s2: :s3, s3: :s1 }
  }
  canvas {
    sizeHint 200
    rect {
#       sizw
      brush through_state: { s1: :blue, s2: :red, s3: :yellow }
    }
  }
}