#!/usr/bin/ruby1.9.1

# Sends a SHUT UP event to port ARGV[0]

# Since Roland E-80 (expensive though it may be) has no such button
# and aplaymidi violates the midi standard(!) buy allowing ^C to interrupt
# it.

# NOW It does send (I think) the right bytes, but nothing ever happens.
# But I found another way to fix it. Restart the aplaymidi command and let
# it run to the end.
# What if I send 128 * 16 note off events?
# That causes EINVAL midway. Also bytes remaining in queue grows to 16380...
# So this learns us
#    the default queuespace == 16384 == 2**14
#    you MUST use a queue, or at least start q 0?
#    The ALSA API proves ones more to be crappy.  There is nothing invalid about the parameters....
require_relative 'sequencer'
include RRTS
Sequencer.new('rplaymidi') do |sequencer|
  out_port = sequencer.parse_address ARGV[0]
  src_port = MidiPort.new sequencer, 'panic', midi_generic:true, application:true
  src_port.connect_to out_port
  require_relative 'midiqueue'
  queue = MidiQueue.new(sequencer, "panic")
#   queue = nil   # and you get EINVAL on drain_output
  # NOTE: the API looks ugly.
  # It should somehow be possible to use subscription here. We tie src+dst+q together into
  # one new entity. Unfortunately there is no example.
  sequencer << ControllerEvent.new(1..16, :panic, sender: src_port, dest: out_port,
                                   sender_queue: queue) <<
               ControllerEvent.new(1..16, :all_notes_off, sender: src_port, dest: out_port,
                                   sender_queue: queue) <<
               ControllerEvent.new(1..16, :reset_controllers, sender: src_port, dest: out_port,
                                   sender_queue: queue) <<
               ResetEvent.new(sender: src_port, dest: out_port, sender_queue: queue)
  # NOTE: on Roland E-80 above stuff has no effect whatsoever
  # It may be because my events are still bogus
  # But the NOTEOFF trick below works!
  sz = sequencer.output_buffer_size
  for note in 0..127
#     STDERR.puts("NOTE = #{note}")
    remaining = sequencer.event_output(NoteOffEvent.new(1..16, note, sender: src_port, dest: out_port,
                                                        sender_queue: queue))
#     puts "remaining = #{remaining}, output_buffer_size=#{sz}"
    if sz - remaining < 500
      sequencer.drain_output
      sequencer.sync_output_queue  # I get: operation not permitted ???????????????????
    end
  end
end
