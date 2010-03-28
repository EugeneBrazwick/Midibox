#!/usr/bin/ruby -w

=begin

to test:

  if two sequencer are operational at the same time how can I than
  trap the INT signal (and others) so notes do not linger?

  Can each seq. has its own trap?
=end

begin
  puts "5 seconds to rescue"
  sleep 5
rescue Interrupt  # but not a standard error!
  puts "rescued..."
end

Signal.trap(:INT) { puts 'INT1'  }

puts "5 seconds to test 1:"
sleep(5);
Signal.trap(:INT) { puts 'INT2!!!'  }
puts "5 seconds to test 2:"
sleep(5);

# learned:  it OVERWRITES
# so a process must have a list of all its currently running sequencers!!
# NOT.
