#!/usr/bin/ruby -w

require 'rrts/rrts'

include RRTS
include Driver

block = nil
Signal.trap(:INT) do |s|
  tag("INTTERRUPTED!!")
  Thread.kill(block) if block
end

tag "the idea is that ^C does not work, since block_test blocks it"
block_test(5)
tag "KLANG!"

# problem:  the sequencer drain method seems to temporarily block SIGINT.
# Can we circumvent that using fibers
block = Fiber.new do
  tag "FIBER test. The idea is that ^C does not work, since ruby blocks too...."
  block_test(5)
  tag "KLANG!"
end

block.resume

# sleep(4)
block = Thread.new do
  tag "the idea is that ^C does work, since the main thread should remain working"
  block_test_ruby_sleep(5)
  tag "KLANG!"
end

=begin
it DOES NOT WORK?? WTF

Does signal() work for all threads??  YES
Now using pthread_sigmask

The result is that ^C is now caught, but unhandled until the thread returns from block_test.
But before the join (this is important).

This is probably totally different from how a C program works with the same construction.

With block_test
  - calling join
  - 5 seconds nothing
  - INTERRUPTED
  - KLANG
  - OK

With block_test_pure_sleep
  The very same sequence!!

With ruby_sleep:
  - calling join
  - INTERRUPTED
  - 5 seconds nothing
  - KLANG
  - OK

Nice... now trap can kill thread. No more KLANG!
=end
tag "calling join\n\n\n"
block.join
tag "OK"
