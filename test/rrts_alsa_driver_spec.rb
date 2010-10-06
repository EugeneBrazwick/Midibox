#!/usr/bin/ruby
# test suite for alsa mappings using rspec
# Run through rake or from toplevel (example)
#   spec rrts_alsa_driver_spec.rb --color --example AlsaQueueInfo_i
require 'spec'
require 'rrts/driver/alsa_midi'
include RRTS
include Driver

describe AlsaQueueInfo_i do
#   before do end
  it 'should keep track of set parameters' do
    q = queue_info_malloc
    q.flags.should == 0       # flags is not even used in alsa-lib/alsa-tools/alsa-seq/alsa-utils
    q.should_not be_locked
    q.name.should be_empty
    q.owner.should == 0
    q.name = 'hallo'
    q.name.should == 'hallo'
  end

  it 'can be set for a sequencer' do
    seq = seq_open
    # there is no queue
    -> { q = seq.queue_info(0) }.should raise_error(AlsaMidiError)
    qid = seq.alloc_named_queue 'hallo'
    queue = seq.queue_info(qid)
    queue.flags.should == 0       # flags is not even used in alsa-lib/alsa-tools/alsa-seq/alsa-utils
    queue.should be_a(AlsaQueueInfo_i)
    queue.name.should == 'hallo'
    queue.owner.should == seq.client_id
    queue.should be_locked
    queue.locked = false
    queue.should_not be_locked
    # I think the next is the same, but it is not... It can be used, but not altered?
    seq.queue_usage?(qid).should == true
    seq.set_queue_usage(qid, false)
    seq.queue_usage?(qid).should == false
    # you can pass a MidiQueue, but not AlsaQueueInfo_i.
    -> { seq.free_queue(queue) }.should raise_error(TypeError)
    seq.free_queue(qid)
    seq.close
  end
end

describe AlsaQueueStatus_i do
  it 'can be retrieved for a sequencer' do
    seq = seq_open
    # but we need a queue
    -> { seq.queue_status(0) }.should raise_error(AlsaMidiError)
    qid = seq.alloc_named_queue 'hallo'
#     queue = seq.queue_info(qid)
    status = seq.queue_status(qid)
    status.should be_a(AlsaQueueStatus_i)
    status.queue.should == qid
    copy = status.copy_to
    copy.queue.should == qid
    # since this is a new queue, all should be 0:
    status.events.should == 0
    status.tick_time.should == 0
    status.real_time.should == [0, 0]
    status.status.should == 0
    # Starting queue seems to do nothing with the status.
    # But you know, it OBVIOUSLY needs to be refetched.
    seq.start_queue(qid)
    status = seq.queue_status(qid)
    status.should_not be_running
    # you MUST flush the buffers before the event is sent.
    seq.drain_output
    status = seq.queue_status(qid)
    status.should be_running
    seq.stop_queue(qid)
    seq.drain_output
    status = seq.queue_status(qid)
    status.should_not be_running
    seq.free_queue(qid)
    seq.close
  end
end

describe AlsaQueueTempo_i do
  it 'can be retrieved through seq' do
    seq = seq_open
    # but we need a queue
    -> { seq.queue_tempo(0) }.should raise_error(AlsaMidiError)
    qid = seq.alloc_named_queue 'hallo'
    tempo = seq.queue_tempo(qid)
    tempo.queue.should == qid
    tempo.skew.should == 0x10_000
    tempo.skew_base.should == 0x10_000
#     puts "ppq=#{tempo.ppq}, usecs_per_beat=#{tempo.usecs_per_beat}"
    tempo.ppq.should == 96 # pulses per quarter/beat = 384 per bar where the signature is 4/4
    tempo.usecs_per_beat.should == 500_000 # 120 beats/quarters per minute
    tempo.ppq = 60
    tempo.ppq.should == 60
    tempo.usecs_per_beat = 1_000_000 # 60 quarters per minute
    tempo.tempo.should == 1_000_000
    # speed up the queue, twice as fast:
    tempo.skew = 2.0
    tempo.skew.should == 0x20000
    tempo.skew_base.should == 0x10000
    seq.free_queue(qid)
    seq.close
  end
end

describe AlsaSequencer_i do
  it 'can be opened' do
    seq = seq_open
    seq.client_id.should >= 128
    seq.client_id.should <= 191
    seq.name.should == 'default'
    seq.close
  end

  it 'should give us access to system info' do
    seq = seq_open
    info = seq.system_info
#     puts "clnts=#{info.clients}, cur=#{info.cur_clients}, prts=#{info.ports},qs=#{info.queues},cur=#{info.cur_queues},ch=#{info.channels}"
    info.clients.should >= 100
    info.cur_clients.should >= 3
    info.ports.should >= 200
    info.queues.should >= 4
    info.cur_queues.should >= 0
    qid = seq.alloc_named_queue('ollah')
    info = seq.system_info
    info.cur_queues.should >= 1
    # actually Alsa supports 256 channels and this must mean 'per port'. This is because it is an
    # 'unsigned char' internally. This means it can be abused for storing tracknrs instead... We'll see.
    info.channels.should == 256
    seq.free_queue(qid)
    seq.close
  end

  it 'should give us access to all ports on the system' do
    seq = seq_open
    clientinfo = client_info_malloc
    portinfo = port_info_malloc
    clientinfo.client = -1
    count = 0
    while seq.query_next_client(clientinfo)
#       puts "clientinfo:name=#{clientinfo.name}, broadcast=#{clientinfo.broadcast_filter?},bounce=#{clientinfo.error_bounce?}, events_lost=#{clientinfo.events_lost}, num_ports=#{clientinfo.num_ports},type=#{clientinfo.type}"
      clientinfo.client.should >= 0
      clientinfo.client.should < 255
      clientinfo.num_ports >= 1          # not really true
      clientinfo.type.should satisfy { |v| v == SND_SEQ_USER_CLIENT || v == SND_SEQ_KERNEL_CLIENT }
      count += 1
      portinfo.client = clientinfo.client
      portinfo.port = -1
      while seq.query_next_port(portinfo)
        (cid = portinfo.client).should == clientinfo.client
        (pid = portinfo.port).should >= 0
        portinfo.port.should < 253
        portinfo.addr.should == [cid, pid]
#         portinfo.should be_port_specified     NOT SO. Even though a port is set...
# the reason is that it is a separate field (haha)
        portinfo.should_not be_port_specified
#         puts "name : #{portinfo.name}, addr=#{portinfo.addr.inspect}"
      end
    end
    count.should >= 3
    seq.close
  end

  it 'should be able to read an event if send to itself' do
    seq = seq_open
    cid = seq.client_id
    port_out = seq.create_simple_port('out', SND_SEQ_PORT_CAP_READ | SND_SEQ_PORT_CAP_SUBS_READ,
                                      SND_SEQ_PORT_TYPE_SOFTWARE | SND_SEQ_PORT_TYPE_APPLICATION |
                                      SND_SEQ_PORT_TYPE_MIDI_GENERIC )
    port_in = seq.create_simple_port('in', SND_SEQ_PORT_CAP_WRITE | SND_SEQ_PORT_CAP_SUBS_WRITE,
                                     SND_SEQ_PORT_TYPE_SOFTWARE | SND_SEQ_PORT_TYPE_APPLICATION |
                                     SND_SEQ_PORT_TYPE_MIDI_GENERIC )
    # Now the clever trick to test events without a real keyboard, abuse midi through:
    # locate midi through port first:
    clientinfo = client_info_malloc
    clientinfo.client = -1
    located = false
    while seq.query_next_client(clientinfo)
      if clientinfo.name =~ /Midi.*Through/i
        located = true
        break
      end
    end
    raise 'Problem: Midi Trough not available(???)' unless located
    midi_through = clientinfo.client
    # I assume illegally that the port is 0
    subs = port_subscribe_malloc
    subs.sender = [cid, port_out]
    subs.dest = [midi_through, 0]
    seq.subscribe_port(subs)
    subs.sender = [midi_through, 0]
    subs.dest = [cid, port_in]
    seq.subscribe_port(subs)

    ev = ev_malloc
    ev.clear
    ev.set_noteon(0, 65, 100)
    ev.source = [cid, port_out]  # cid is automatically done, but this looks better
    ev.set_broadcast_to_subscribers # which is midi through now.
    ev.dest.should == [SND_SEQ_ADDRESS_SUBSCRIBERS, SND_SEQ_ADDRESS_UNKNOWN]
    ev.set_direct
    seq.event_output ev

    # reuse it
    ev.clear
    ev.set_noteoff(0, 65)
    ev.source = [cid, port_out]
    ev.set_broadcast_to_subscribers
    ev.set_direct
    seq.event_output ev
    seq.drain_output

    ev1 = seq.event_input
    ev1.type.should == SND_SEQ_EVENT_NOTEON
    ev1.source.should == [midi_through, 0]
    ev1.channel.should == 0
    ev1.note.should == 65
    ev1.velocity.should == 100

    ev2 = seq.event_input
    ev2.type.should == SND_SEQ_EVENT_NOTEOFF
    ev2.source.should == [midi_through, 0]
    ev2.dest.should == [cid, port_in]
    ev2.channel.should == 0
    ev2.note.should == 65
    ev2.velocity.should == 0
    seq.close
  end
end
