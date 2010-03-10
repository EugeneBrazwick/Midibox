#!/usr/bin/ruby -w
# midiroute.c by Matthias Nagorni
# see http://www.suse.de/~mana/midiroute.c

MAX_MIDI_PORTS =4

#/* Read events from writeable port and route them to readable port 0  */
# /* if NOTEON / OFF event with note < split_point. NOTEON / OFF events */
#/* with note >= split_point are routed to readable port 1. All other  */
#/* events are routed to both readable ports.                          */
def midi_route(seq, out_ports, split_point)
  loop do
    (ev, more = seq.event_input) or break
    ev.set_subs
    ev.set_direct
    case ev
    when NoteOnEvent, NoteOffEvent
      if ev.note < split_point
        ev.source = out_ports[0]
      else
        ev.source = out_ports[1]
      end
      seq.event_output_direct ev
    else
      ev.source out_ports[0]
      seq.event_output_direct ev
      ev.source = out_ports[1]
      seq.event_output_direct ev
    end
    break if b == 0 #unless seq.event_input_pending(false)
  end
end


if (ARGV.length < 1)
  STDERR.printf("\nmidiroute <split_point>\n\n");
  exit(1);
end
split_point = Integer(ARGV[0]);
#/* Open ALSA sequencer wit num_in writeable ports and num_out readable ports. */
#/* The sequencer handle and the port IDs are returned.                        */
# 1 in port, 2 out ports
num_in, num_out = 1, 2
require_relative 'sequencer'
include RRTS
Sequencer.new('MIDI Router') do |seq|
  in_ports = []
  for i in (0...num_in) do
    portname = "MIDI Router IN #{i}"
    in_ports << MidiPort.new(seq, portname, write: true, subs_write: true, application: true)
  end
  out_ports = []
  for i in (0...num_out)
    portname = "MIDI Router OUT #{i}"
    out_ports << MidiPort.new(seq, portname, read: true, subs_read: true, application: true)
  end
  descriptors = seq.poll_descriptors(Sequencer::PollIn)
  loop do
    revents = descriptors.poll(100_000) or next
#   if (poll(pfd, npfd, 100000) > 0) ????
    midi_route(seq, out_ports, split_point);
  end
end

