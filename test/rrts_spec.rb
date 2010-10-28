#!/usr/bin/ruby
# test suite for nodes using rspec
# Run through rake or from toplevel
# Example:
#   rspec rrts_spec.rb --color --pattern Sequencer

require 'rrts/sequencer'
require 'rrts/midiqueue'

include RRTS

# I use the same examples as rrts_alsa_driver_spec.rb
# as far as this is usefull.
describe MidiQueue do
#   before do end
  it 'should keep track of set parameters' do
    Sequencer.new do |seq|
      q = seq.create_queue 'qt'
      q.sequencer.should == seq
      info = q.info
      info.flags.should == 0
      info.should be_locked
      info.name.should == 'qt'
      info.owner.should == seq.client_id
      info.name = 'hallo'
      info.name.should == 'hallo'
    end
  end

  it 'can be set for a sequencer' do
    Sequencer.new do |seq|
      queue = seq.create_queue 'hallo'
      queue.info.flags.should == 0       # flags is not even used in alsa-lib/alsa-tools/alsa-seq/alsa-utils
      queue.should be_a(MidiQueue)
      queue.name.should == 'hallo'
      queue.owner.should == seq.client_id
      queue.should be_locked
      queue.locked = false
      queue.should_not be_locked
      # I think the next is the same, but it is not... It can be used, but not altered?
      queue.should be_usage
      queue.usage = false
      queue.should_not be_usage
    end
    Sequencer.new do |seq|
      seq.cur_queues.should == 0
    end
  end

  it 'can be used to get or set the queuestatus' do
    Sequencer.new do |seq|
      # but we need a queue
      queue = seq.create_queue 'hallo'
      seq.queue('hallo').should == queue
      status = queue.status
      status.should be_a(Driver::AlsaQueueStatus_i)
      status.queue.should == queue.queue
      copy = status.copy_to
      copy.queue.should == queue.queue
      # since this is a new queue, all should be 0:
      status.events.should == 0
      status.tick_time.should == 0
      status.real_time.should == [0, 0]
      status.status.should == 0
      # Starting queue seems to do nothing with the status.
      # But you know, it OBVIOUSLY needs to be refetched.
      queue.start
      queue.should_not be_running
      # you MUST flush the buffers before the event is sent.
      seq.flush
      queue.should be_running
      queue.stop(:flush)
      queue.should_not be_running
    end
  end

  it 'can be used to set and get the tempo' do
    Sequencer.new do |seq|
      queue = seq.create_queue 'hallo'
      tempo = queue.tempo
      tempo.queue.should == queue.queue
      tempo.skew.should == 0x10_000
      tempo.skew_base.should == 0x10_000
      queue.skew.should be_close(1.0, 0.000001)
  #     puts "ppq=#{tempo.ppq}, usecs_per_beat=#{tempo.usecs_per_beat}"
      tempo.ppq.should == 96 # pulses per quarter/beat = 384 per bar where the signature is 4/4
      queue.ppq.should == 96
      tempo.usecs_per_beat.should == 500_000 # 120 beats/quarters per minute
      queue.ppq = 60 # 96 is a bit of a standard, you know
      queue.ppq.should == 60
      queue.usecs_per_beat = 1_000_000 # 60 quarters per minute
      queue.usecs_per_beat.should == 1_000_000
      # speed up the queue, twice as fast:
      queue.skew = 2.0
      queue.skew.should be_close(2.0, 0.000001)
    end
  end
end

describe Sequencer do
  it 'can be opened' do
    Sequencer.new('boomerang') do |seq|
      seq.client_id.should >= 128
      seq.client_id.should <= 191
      seq.name.should == 'default'
      seq.client_name.should == 'boomerang'
    end
  end

  it 'should give us access to system info' do
    Sequencer.new('boomerang') do |seq|
      info = seq.system_info
      info.clients.should >= 100
      seq.cur_clients.should >= 3
      info.ports.should >= 200
      info.queues.should >= 4
      (cur_queues = seq.cur_queues).should >= 0
      seq.cur_clients.should == info.cur_clients
      seq.cur_queues.should == info.cur_queues
      queue = seq.create_queue('ollah')
      seq.cur_queues.should == cur_queues + 1
    end
  end

  it 'should give us access to all ports on the system' do
    Sequencer.new('boomerang') do |seq|
      seq.ports.each_value do |port|     # beware the Hash... It's not 'each'!
#         tag "port = #{port}"
        port.client_id.should >= 0
        port.client_id.should < 255
        port.client.type.should satisfy { |v| v == Driver::SND_SEQ_USER_CLIENT || v == Driver::SND_SEQ_KERNEL_CLIENT }
        port.port.should >= 0
        port.port.should < 253
        port.addr.should == [port.client.client, port.port]
      end
    end
  end

  it 'should be able to read an event if send to itself' do
    Sequencer.new('boomerang') do |seq|
      queue = seq.create_queue 'boom'
      port_out = seq.create_port 'out', read: true, subscription_read: true, software: true, application: true,
                                 midi_generic: true
      port_in = seq.create_port 'in', write: true, subscription_write: true, software: true, application: true,
                                midi_generic: true
      port_out.address.should be_a(Array)
      port_in.address.should be_a(Array)
      # Now the clever trick to test events without a real keyboard, abuse midi through:
      midi_through_port = seq.port(/Midi.*Through.*Port.*0/i)
      midi_through_port.address.should be_a(Array)
      sub_out, sub_in = seq.subscribe any_subscribers: true, port_out => midi_through_port, midi_through_port => port_in
      sub_out << NoteOnEvent.new(1, 'A4', 100) << NoteOffEvent.new(1, 'A4') << FlushEvent.new

      ev1 = seq.event_input
      ev1.should be_a(NoteOnEvent)
      ev1.source.should == midi_through_port
      ev1.channel.should == 1
      Driver::decode_a_note('A4').should == 57
      ev1.note.should == Driver::decode_a_note('A4')
      ev1.velocity.should == 100

      ev2 = seq.event_input
      ev2.should be_a(NoteOffEvent)
      ev2.source.should == midi_through_port
      ev2.dest.should == port_in
      ev2.channel.should == 1
      ev2.note.should == Driver::decode_a_note('A4')
      ev2.velocity.should == 0
    end
  end
end

