#!/usr/bin/ruby

require_relative '../../app'

Reform::app {
  # this is an extremely dirty trick...
  # tomorrow I'll show how to implement it using a generic Widget!
  analogclock
}