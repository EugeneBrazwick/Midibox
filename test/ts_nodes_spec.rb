#!/usr/bin/ruby
# test suite for nodes using rspec
# Otherwise run (example)
#      spec ts_nodes_spec.rb --color --example Node::MidiFileReader
require 'rrts/rrts'
require 'rrts/node/track'
include RRTS
include Node

# tag "HERE?"

# The Consumer/Producer classes are not tied to midievents.
# The only requirement is that the elements have a 'tick'
# This can just be the time in seconds, using a floating point
# timer with a nanosecond resolution (1_000_000_000 ns == 1 s)
# just say Time.new.to_f - time0.to_f
# Timestamps are relative to the start of the 'queue'. Let's say
# the time the recording or playback started. Note that this is
# still called 'absolute' time.
class MockEvent
  private
    def initialize tick, bogo
      @tick, @bogo = tick, bogo
    end
  public
    attr :tick
    attr_accessor :bogo
end

# since Producer is abstract it will not do a lot.
class MockProducer  < Producer

    # the events that we will produce
    Data = {0.0001 => :hallo,
            0.0010 => :world,
            0.02   => :more,
            0.043  => :great,
            0.12   => :things,
            0.5    => :will,
            1.0    => :follow,
            1.1    => 'ifyouwaitlong',
            1.2    => 'anddontforgetthecommas',
            1.4    => :enough
            }
  public

    # override
    def each
      return to_enum unless block_given?
      Data.each { |k, v| yield MockEvent.new(k, v) }
    end
end

class MockConsumer < Consumer
  private
    def initialize producer = nil, options = nil
      @show_events = false # options must be set to defaults BEFORE calling 'super'
#       tag "Calling super for #{self}"
      super
#       tag "done"
      @receive_count = 0
      @data = {}
    end

    def parse_option k, v
      case k
      when :show_events then @show_events = v
      else super
      end
    end

  public
    # override
    def consume producer, &when_done
      each_fiber(when_done) do |ev|
        if ev
          tag("Received at %.5f %s" % [Time.now.to_f, ev.inspect]) if @show_events
          @data[ev.tick] = ev.respond_to?(:bogo) ? ev.bogo : ev
          @receive_count += 1
        end
      end
          # *IMPORTANT*: any code here is executed BEFORE the loop!!
          # I mean to say, there should not be any code here. It must return
          # the result from the 'each_fiber' call.
    end

    attr :data, :receive_count
end

describe Producer do
  it 'should produce events' do
    producer = MockProducer.new
    producer.run
  end

  # that didn't do a lot.... It did nothing. There are no consumers!!!

  it 'should produce events for some consumer' do
    t0 = Time.new
    producer = MockProducer.new
    consumer = MockConsumer.new(producer)
    producer.run
    consumer.data.should == MockProducer::Data
    t1 = Time.new
    (t1 - t0).should < 1.0  #within a second
  end

  # What about the timings?
  # The events are supposed to be enqueued in an Alsa queue. That queue is responsible for
  # the timed delivery of the event.
  # In our simple case the data was all 'spammed'.
  # Fortunately we can control the 'spamming' using write_ahead and sleeptime.
  it 'should delay events' do
    t0 = Time.new
    producer = MockProducer.new(write_ahead: 0.2, sleeptime: 0.1)
    consumer = MockConsumer.new(producer)
    producer.run
    consumer.data.should == MockProducer::Data
    t1 = Time.new
    (t1 - t0).should > 1.0  #guaranteed more than a second
  end
end

describe 'Filter' do
  it 'should be chainable' do
    t0 = Time.new
    producer = MockProducer.new
    f1 = Filter.new producer
    f2 = Filter.new f1
    f3 = Filter.new f2
    f4 = Filter.new f3
    consumer = MockConsumer.new(f4)
    producer.run
    consumer.data.should == MockProducer::Data
    consumer.receive_count == MockProducer::Data.length
    t1 = Time.new
#     tag "This took %.6f seconds" % (t1 - t0)   # 3 ms
  end

  it 'should be splittable' do
    t0 = Time.new
    producer = MockProducer.new
    f1 = Filter.new producer
    f2 = Filter.new producer
    f3 = Filter.new producer
    f4 = Filter.new producer
    consumer = MockConsumer.new([f1, f2, f3, f4])#  show_events: true)
    producer.run
    # CUNNING! You know, consumer received each event 4 times, but since he stores a hash
    # the values overwrite each other.... :)
    # Not to worry, the insertion order does not matter for Hash equality.
    # But this is still a fixed situation since only Producer will run a thread,
    # while Filter is passive.
    consumer.data.should == MockProducer::Data
    # However:
    consumer.receive_count == MockProducer::Data.length * 4
    t1 = Time.new
#     tag "This took %.6f seconds" % (t1 - t0)   # 35 ms
  end

  it 'should filter something' do
    producer = MockProducer.new
    f1 = Filter.new producer do |event| event.bogo != :great end
    consumer = MockConsumer.new(f1)
    producer.run
    consumer.data.has_value?(:great).should == false
    consumer.receive_count == MockProducer::Data.length - 1
    consumer.data[0.043] = :great
    consumer.data.should == MockProducer::Data
  end

  it 'should multi thread' do
    t0 = Time.new
    prods = []
    4.times do
      prods << MockProducer.new(write_ahead: 0.5, sleeptime: 0.3)
    end
    consumer = MockConsumer.new(prods)#  show_events: true)
    prods.map(&:produce).map(&:join)
    consumer.receive_count == MockProducer::Data.length * 4
    t1 = Time.new
    (t1 - t0).should >= 0.8  # note there is some inaccuracy
    # this is not a good test, since the order of the events matters.
    # if the produce calls are not multithreaded one would expect
    # that each producer dumps a complete list.
    # But we receive :hallo, :hallo, :hallo, ..... :enough, 'anddontforgetthecommas', :enough
    # So this is reasonably mixed.
  end
end

require 'rrts/node/mapper'

describe Mapper do
  it 'can be used to alter events' do
    producer = MockProducer.new
    mapper = Mapper.new producer do |event| event.bogo = :ni end
    consumer = MockConsumer.new(mapper)
    producer.run
#     tag "data = #{consumer.data.inspect}"
    consumer.data.all?{|k,v| v == :ni}.should == true
  end
end

# Splitter is same as Filter but we get a stream of OK-ed events, and another with rejects.
# It could use a 'case' even.

require 'rrts/node/splitter'

describe Identity do
  it 'is the same an "always true" filter' do
    producer = MockProducer.new
    ident = Identity.new(producer)
    c1 = MockConsumer.new(ident)
    ident2 = Identity.new(ident)
    c2 = MockConsumer.new(ident2)
    producer.run
    c1.data.should == MockProducer::Data
    c2.data.should == MockProducer::Data
  end
end

describe Splitter do
#   tag "HEEEEREEE!"
  it 'is the same as a MultiFilter' do
#     tag "HERE!!!"
    producer = MockProducer.new
    splitter = Splitter.new(producer)
#     tag "assign condition 1"
    cond1 = splitter.condition(:begins_with_vowel) do |ev|
#       tag("ev=#{ev}")
      ev.bogo.to_s[0] =~ /[aeiouy]/
    end
    cond1.should be_a(Consumer)
#     tag "assign cond2, cond1 = #{cond1}"
    cond2 = splitter.condition(:begins_with_w) { |ev| ev.bogo.to_s[0] == 'w' }
    c1 = MockConsumer.new(cond1)
    c2 = MockConsumer.new(cond2)
    c3 = MockConsumer.new(splitter[:begins_with_vowel])
    producer.run
#     tag "c1.data = #{c1.data.inspect}"
    c1.data.all?{|k,v| v.to_s[0] =~ /[eiuoay]/}.should == true
    c2.data.all?{|k,v| v.to_s[0] == 'w' }.should == true
    c3.data.all?{|k,v| v.to_s[0] =~ /[eiuoay]/}.should == true
  end
end

def file_del *files
  for i in files
    File::delete(i) if File.exists?(i)
  end
end

require 'rrts/node/midifilereader'
require 'rrts/node/chunk'
require 'timeout'

EuroDanceMid = File.dirname(__FILE__) + '/../fixtures/eurodance.midi'
EuroDanceYaml = File.dirname(__FILE__) + '/../fixtures/eurodance.yaml'

describe MidiFileReader do
  before do
    Track::reset_key
    # the default is to immediately read the entire file.
    # And use 'non-spam' mode for 'each'. This means that
    # we run no more than three seconds ahead of the current time.
    @input = MidiFileReader.new(EuroDanceMid, split_channels: true,
                                spam: true # !
                               )
  end

  it "should be able to setup properly" do
#       STDERR.puts "yes?"
  end

  it "should split_channels must be set" do
    @input.split_channels?.should == true
  end

    # the events have no track!??
    # that's normal, since MidiFileReader doesn't bother about tracks anymore
    # But if there are several tracks in the MIDI file I now no longer have the connection
    # So that's wrong!
  it "should create events with a track" do
    @input.find_all { |ev| ControllerEvent === ev }.all? { |ev| ev.track }.should == true
  end

  it "should contain 1767 events" do
    # these events are NEVER processed
    @input.count.should == 1767
      # and 'each' does a rewind? NO. Cannot, stream closed due to auto_close
#       assert_equal(1767, @input.count)
      # also, count uses each which always 'spams' (fortunately)
  end

  it "cannot be fooled by a fool" do
    t0 = Time.now

# interesting example of how things fail...

    input2 = MidiFileReader.new(EuroDanceMid, split_channels: true)
    input2.run

#What's wrong with this?

#The 'run' code is quite clever. There are no consumers, and as such 'running' is useless.
#It will return immediately.
    (Time.now - t0).should <= 0.1
  end

  it "create a non spamming thread for 'run'" do
    t0 = Time.now
    input2 = MidiFileReader.new(EuroDanceMid, split_channels: true)
    cons = MockConsumer.new(input2)  # kind of '/dev/null'
    begin
      # I tear it down. Because otherwise it takes far too long
      Timeout::timeout(3.0) do
        # run will read the MIDI ticks and send them in a controlled way to the consumer.
        # But *not* exactly on time
        # We leave that to the Alsa queue system (smart as we are)
        # You cannot possibly think a ruby program can send realtime events
        input2.run
      end
    rescue Timeout::Error
    end
    (Time.now - t0).should >= 3.0
    cons.receive_count.should >= 400
  end

  it "should run a spamming thread quickly" do
    t0 = Time.now
    cons = MockConsumer.new(@input)  # kind of '/dev/null'
    @input.run
    (Time.now - t0).should <= 0.7
    cons.receive_count.should == 1767
  end

end

describe Chunk do
  it "should create 9 tracks with 985 events" do
    input = MidiFileReader.new(EuroDanceMid, split_channels: true, spam: true)
    chunk = Node::Chunk.new(input)
    chunk.track.should == nil
    input.run
    chunk.track.should_not == nil
    chunk.listing.count.should == 9
    chunk.listing[0].should be_a(Track)
    # This enumerates chunk:
    chunk.count.should == 985
    # read: should STILL be 985, since it calls 'each' again.
    chunk.count.should == 985
    # but attempt to reiterate input will fail:
    -> do input.count end.should raise_error(IOError)
  end
end

describe MidiPipeReader do
  it "should create 9 tracks with 985 events" do
    input = MidiPipeReader.new('cat ' + EuroDanceMid, split_channels: true, spam: true)
    chunk = Node::Chunk.new(input)
    chunk.track.should == nil
    input.run
    chunk.track.should_not == nil
    chunk.listing.count.should == 9
    chunk.listing[0].should be_a(Track)
    # This enumerates chunk:
    chunk.count.should == 985
    # read: should STILL be 985, since it calls 'each' again.
    chunk.count.should == 985
    # but attempt to reiterate input will fail:
    -> do input.count end.should raise_error(IOError)
  end
end

require 'rrts/node/midifilewriter'

describe MidiFileWriter do
  before do
    Track::reset_key      # reset the trackid generator
    @input = MidiFileReader.new(EuroDanceMid, no_tampering: true, spam: true)
#     tag "creating @output"
    @output = MidiFileWriter.new('/tmp/t.midi', @input)
#     tag "OK"
  end

  it  "should save MIDI exactly as being read" do
#     tag "Calling run"
    @input.run
#     tag "Executing: diff /tmp/t.midi #{EuroDanceMid}"
    `diff /tmp/t.midi #{EuroDanceMid}`
#     tag "test exitstatus #{$?}"
     $?.exitstatus.should == 0
  end

  it "should create something that can be read" do
    @input.run
    MidiFileReader.new('/tmp/t.midi').count.should == 1767
  end
end

require 'rrts/node/yamlwriter'

describe YamlFileWriter do
  before do
    Track::reset_key
    @input = MidiFileReader.new(EuroDanceMid, no_tampering: true, spam: true)
    @output = YamlFileWriter.new('/tmp/t.yaml', @input)
  end

  it "should save properly" do
    @input.run
    `file --brief /tmp/t.yaml`.chomp.should =~ /ASCII text/
    `diff /tmp/t.yaml #{EuroDanceYaml}`
     $?.exitstatus.should == 0
  end

end

require 'rrts/node/yamlreader'

describe YamlFileReader do
  before do
    file_del('/tmp/t.yaml')
    Track::reset_key
    input = MidiFileReader.new(EuroDanceMid, no_tampering: true, spam: true)
    YamlFileWriter.new('/tmp/t.yaml', input)
    input.run
    @input = YamlFileReader.new('/tmp/t.yaml', spam: true)
  end

  it "should save properly" do
    file_del('/tmp/t2.yaml')
#     assert(@input.consumers, 'consumers not set in producer')
    @input.consumers.should_not == nil
    YamlFileWriter.new('/tmp/t2.yaml', @input)
    @input.run
    File.exists?('/tmp/t2.yaml').should == true # , 'YamlFileWriter dit not write (or close?) file')
    `diff /tmp/t.yaml /tmp/t2.yaml`
    $?.exitstatus.should == 0
  end

  it "should work with timing as well" do
    t0 = Time.now
    input = YamlFileReader.new('/tmp/t.yaml')
    output = MockConsumer.new(input)
    begin
      Timeout::timeout(3.0) do
#         tag "RUN"
        input.run
      end
    rescue Timeout::Error
    end
    (Time.now - t0).should <= 5.0
    output.receive_count.should < 500
  end

  it "should have the same events as the midifilereader" do
    file_del('/tmp/t4.yaml')
    c0 = MidiFileReader.new(EuroDanceMid, no_tampering: true, spam: true).count
    YamlFileWriter.new('/tmp/t4.yaml', @input)
    @input.run
    File.exists?('/tmp/t4.yaml').should == true
#     tag "MACHINERY1: #{MidiFileReader.new(EuroDanceMid, no_tampering: true, spam: true).map{|ev|ev.class}.inspect}"
    c1 = MidiFileReader.new(EuroDanceMid, no_tampering: true, spam: true).count
#     tag "MACHINERY2: #{YamlFileReader.new(EuroDanceYaml, spam: true).map{|ev|ev.class}.inspect}"
    c2 = YamlFileReader.new('/tmp/t4.yaml', spam: true).count
#     tag "c1 = #{c1}, c2 = #{c2}"
    c1.should == 1767
    c2.should == c1
    `diff /tmp/t.yaml /tmp/t4.yaml`
    $?.exitstatus.should == 0
  end
end

require_relative '../bin/node_identity'

describe 'I' do

  before do
    Track::reset_key
  end

  it 'should create 2 identical yaml files' do
#       tag "DELETE"
    file_del('/tmp/t6.midi', '/tmp/t5.yaml', '/tmp/t5.yaml')
    # Why does it not understand module Nodes here???
#       tag "create I 1"
#       trace do
    Nodes::I.new('--spam', '--input=fixtures/eurodance.midi',
                 '--output=/tmp/t6.midi', '--no-tampering').run
    File::exists?('/tmp/t6.midi').should == true
#       end
#       tag "create I 2"
    Track::reset_key
    Nodes::I.new('--spam', '--input=fixtures/eurodance.midi',
                  '--output=/tmp/t5.yaml', '--no-tampering').run
    File::exists?('/tmp/t5.yaml').should == true
    Track::reset_key

#       tag "create I 3"
    Nodes::I.new('--spam', '--input=/tmp/t6.midi',
                  '--output=/tmp/t6.yaml', '--no-tampering').run
    File::exists?('/tmp/t6.yaml').should == true
    `diff /tmp/t5.yaml /tmp/t6.yaml`
    $?.exitstatus.should == 0
#       tag "DONE TEST"
  end
end

# Some patience is required, it takes about 30 seconds....
require 'rrts/node/player'
# require 'rrts/midievent'
describe Player do
  it 'should send stuff to a midi port' do
#     producer = MidiFileReader.new(EuroDanceMid)
=begin IMPORTANT NOTICE
if you get bugged with Syck::Objects
then he could not find the classes to instantiate.  MidiEvent etc. must be 'required'!!
=end
    producer = YamlFileReader.new(EuroDanceYaml, spam: true)
    producer.should be_spamming # This is OK, but no use here.  Apparently queueing up events will block the
      # sequencer anyway....
    player = Player.new('Midi Through Port-0', producer)# , spam: true)
#     player.should be_spamming     # That works  BUT IS UTTERLY STUPID!  the player is a consumer!!!
#     player = Player.new('UM-2 MIDI 2', producer)
    producer.run
  end
end

__END__

Typically the nodes that connect to us must all be blocked.
When we receive an event, we delegate it to the first filter whose
condition is true.

Let's say we use enumerators. This is really not a bad solution, but we arrive
at solution I of the TODOlist.

Connecting a condition gives us an internal node, whose each is in fact
  org.find_all { |ev| condition(ev) }

Given Enumerator.new with a block you can build a coroutine that generates a value
and then lets the receiver handle it until the next one is required.

  entor = Enumerator.new do |yielder|
            produce event
            yielder.yield(event)
          end

  for ev in entor ....
  end

That's one block.  But can I make 16 out of it? We need fibers or threads.
Because the consumer of the events blocks the stream until it is done.

We could say I have 16 yielders iso one.

Could using 'next' help?  No. We would have to create a system where we can signal
one of the readers to call next.  This is just making things difficult.

Interestingly enough Fiber is almost the same as Enumerator. Change 'next' into 'resume'
and it is obvious.
So we would still be locked in an unescapable loop.

the STACKED ENUMERATORS solution
================================
Our blocking can be fixed using a stack of filters.
    F4 ch==4
       F3 ch == 3
           F2 ch == 2
               F1 ch == 1
                   Source
F4 performs a 'for i in F3' (where ch == 4)
F3 does 'for i in F2'
etc. and finally F1 does 'for i in Source'
But where must the condition be checked.  If we check it in this pattern F2 will
only receive events with ch == 1.
NOT GOING TO WORK.

Also be wary of the following snag: calling next on a filter of which there are no events
would keep waiting forever. If we use a type II solution we would start reading the
entire Source before returning which is extremely bad.

But the enumerator stack has some interesting properties.  Once the source has an event
ready it is then processed by all readers on the stack. The problem is that you can't
do anything with these events, as pushing them cannot be done.

It would be nice to keep the threaded aspect inside the Splitter itself. But this
cannot be done, since it will immediately introduce the multiple blocking points of
execution problem.

the NO-PULLING solution
=======================
The fact that we designed the initial eventpassing system as 'pulling' does not mean
it has to remain so.  Suppose you had no threads and were using C.
We would make the Splitter the active element.  It reads an event, it pushes it (using
a callback) to all filters matching their condition. The filters push the events further
to their respective writers (or in a general, Destinations).

That looks good, but the reverse problem comes now into view.  It is possible that there
is more than one reader, and passing an event to a consumer may block (player blocks for
example, if an event is too far ahead).

Next problem: whose turn is it?
Currently our connect_to method start executing immediately. This is bad if longer
chains need to be build. In the example above we have more than one yamlwriter.
If we decide that they must block waiting for an event, then they will all block.
How can the event ever arrive in that case?
Basicly any connecting receiver must release control over to the main controller.
Similarly any producer must register as such.

     /> F4-------
  P1 -> F1\      \
  P2/      --> F3 -> C1
  P3 -> F2/       \> C2

P1 is a splitter, as is F3.
F3 cannot be made active.  Can P1? No. For a solution see below.

Active consumers are basicly bad, since we have no idea if an event is available
for one. So the producers must be the active ones? Are there producers?
MidiFileReader, YamlIOReader and Recorder all generate MidiEvent instances, but
recorder cannot be made active easily. Even YamlPipeReader may block on IO input
from somewhere else.
In general we have Processors, and Events. Processors may block on IO or on waiting
for an Event from another (specific) Processor.
Also it would not be uncommon to have 341 different nodes in a big project. Should we
fork 341 threads?

Chains like P1 -> F1 -> F2 -> F3 -> C1 can be executed in a single thread without
any problems. Notation: as given.

The problem seems to be Splitter/Merger specific. So we make one node in the network the
active one.  A splitter will remove the 'active' property from any attached output
and instead will start a push model. This still works if there are several splitters.

  P1 \
      \
  P2 ---> F -> C
      /
  P3 /

Notation: [P1, P2, P3] -> F -> C

Compound nodes work by calculating the event in their input with the smallest tick.
But what it P3 is actually /dev/null?  F will call P3.next and then block forever.

So it sames once more that 'pulling is evil'. And pushing is its mirror image.

the COROUTINES solution
=======================
def run_forever
  loop do
    ...
    # release control
    event = callcc { |c| return c }
    ...
  end
end

coroutine = run_forever
# when time for coroutine to continue (1 step?):
coroutine.call(event)

Once more, there is a correlation with fibers and enumerators here.
We can use fibers on the consumers and not on the producers?

WHO'SE AFRAID OF THREADS?
=========================

OLD SITUATION
=============
Producer:                       def each
                                  produce event
                                  yield event
                                end

Consumer:                       for i in producer do ... end
                            ==  producer.each { |ev| ... }

Can we trick the each method of Splitter so it takes over control?
I think yes. The block passes can be used as the callback for when we have
an event ready. Splendid! But...
Well, the each must return immediately, which is not a problem, except that
our Splitter will have to give up control as well!
Hm....

Splitter.new do |splitter|
  YamlWriter.new(Filter.new(splitter) {|ev| ev.channel == 1})
end

YamlWriter calls Filter.each which calls Splitter.each giving the splitter a new
node.

This would probably work.

If we only have splitters then there is a single source which can serve as an ACTIVE node.
If we only have mergers the last consumer can serve as an active node.
If we have both we must split the system in threads of only mergers, or only splitters.
Once that this is done the active nodes can 'go'.

However, it is very questionable that fibers work well with MT.
Is it? The manual says nothing.
There is also a Fiber lib giving them the 'transfer' method.

     /> F4---------
  P1 -> F1\        \
  P2/      --> F3 -> C1
  P3 -> F2/       \> C2

P1*->[F1->F3->[C1,C2],F4->C1]  +  P2*->F1  +  P3*->F2->F3
[[[P1,P2]->F1,P3->F2]->F3,P1->F4]->C1*  +  F3->C2*

So an array can only appear in 1 route and we can choose to follow the producers first,
or the consumers.  It would also be possible to mix them up. Since P2*->F1 is the same
as P2->F1* (it should sound the same).
It seems important to prefer the one or the other do, since the internals are different.
If producers are active then an event is gathered and then immediately pushed onward.
If consumers are active then control must skip back 1 cycle.
That is active consumers require fibers internally, while active producers do not.

So instead of producer.each we arrive at consumer <<.

Also P1->[F1,F2] is easy. While [F1,F2]->C1 is much harder.
Note that P2*->F1 implies that events arriving in F1 from there
take the same route as in the first element, (so F1->F3->[C1,C2]).
We could also try the bottom most route first. This results in:
P3*->F2->F3->[C1,C2]  +  P2*->F1->F3  +  P1*->[F1,F4->C1]
