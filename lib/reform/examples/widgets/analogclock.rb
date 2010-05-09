#!/usr/bin/ruby

require_relative '../../app'

Reform::app {
  # this is an extremely dirty trick...
  # tomorrow I'll show how to implement it using a generic Widget!
  analogclock {
#     size 200 # this does not work!!!
#     tag "HERE" OK!
#     geometry 100, 100, 400, 400               UTTERLY IGNORED
              # because I'm a toplevel window? and the wm does this???
              # probably. How to switch it off then?
  }
}