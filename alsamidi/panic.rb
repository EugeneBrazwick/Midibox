#!/usr/bin/ruby1.9.1

# Sends a SHUT UP event to port ARGV[0]

# Since Roland E-80 (expensive though it may be) has no such button
# and aplaymidi violates the midi standard(!) buy allowing ^C to interrupt
# it.

require_relative 'sequencer'
include RRTS
Sequencer.new('rplaymidi') do |sequencer|
  out_port = sequencer.parse_address ARGV[0]
  src_port = MidiPort.new sequencer, 'panic', midi_generic:true, application:true
  src_port.connect_to out_port
  sequencer << ControllerEvent.new(:panic)
end