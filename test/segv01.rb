
require_relative '../lib/rrts/driver/alsa_midi'

=begin
Complicated bug conditions. This does not work.
The fact is that poll received a EINTR and handling it cause a rb_raise.
Unfortunately the following poll call refuses to break on CTRL-C.
How can it be different from alsa_midi... ??

The secret: rb_thread_blocking_region! Alter sleep_eintr_test to use it!
It seems however likely that rb_raise is a nono from within rb_thread_blocking_region
so this is more a feature.
=end
t = Thread.new do
  loop do
    begin
      sleep_eintr_test
    rescue Interrupt
      STDERR.print "clean exit\n"
    end
  end
end

t.join