#!/usr/bin/ruby -w

# STDERR.puts "er????"
require_relative '../sequencer'
require_relative '../midiport'

include RRTS

# STDERR.puts "creating Seq"
@seq = Sequencer.new
puts "creating source_port"
@port = MidiPort.new(@seq, 'test_out', midi_generic: true, application: true);
# puts "opening Um-2 Midi-2"
@out_port = @seq.port('UM-2 MIDI 2')
# @queue = MidiQueue.new('test')
# connect the ports:
@port >> @out_port

def play ev
  ev.sender = @port
  ev.dest = @out_port
#   ev.queue = @queue
  @seq << ev
  @seq.flush
end

puts "attempt to play a C4:"
@channel = 10
play NoteOnEvent.new(@channel, 'C4', 100)
sleep 1
play NoteOffEvent.new(@channel, 'C4')
