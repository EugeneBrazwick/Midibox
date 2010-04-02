#!/usr/bin/ruby
# test suite for nodes using shoulda
#  Please use 'rake test' to run, as this sets the pwd correctly
# Otherwise run from toplevel (example)
#               ruby test/ts_nodes.rb -n /identity/
# using '-n' runs only matching 'shoulds'. n == nifty.
require 'rubygems'
require 'test/unit'
require 'shoulda'
require_relative '../lib/rrts/rrts'
require_relative '../lib/rrts/node/track'
include RRTS
# tag "HERE?"

def file_del *files
  for i in files
    File::delete(i) if File.exists?(i)
  end
end

class MidiFileReaderTest < Test::Unit::TestCase
  context 'reader' do
    setup do
      Node::Track::reset_key
      require_relative '../lib/rrts/node/midifilereader'
      # the default is to immediately read the entire file.
      # And use 'non-spam' mode for 'each'. This means that
      # we run no more than three seconds ahead of the current time.
      @input = Node::MidiFileReader.new('fixtures/eurodance.midi', split_channels: true,
                                        spam: true # !
                                       )
    end

    should "be able to setup properly" do
#       STDERR.puts "yes?"
    end

    # the events have no track!??
    # that's normal, since MidiFileReader doesn't bother about tracks anymore
    # But if there are several tracks in the MIDI file I now no longer have the connection
    # So that's wrong!
    should "create events with a track" do
      assert(@input.find_all { |ev| ControllerEvent === ev }.all? { |ev| ev.track })
    end

    should "split_channels must be set" do
      assert(@input.split_channels?)
    end

    should "should contain 1767 events" do
      # these events are NEVER processed
      assert_equal(1767, @input.count)
      # and 'each' does a rewind? NO. Cannot, stream closed due to auto_close
#       assert_equal(1767, @input.count)
      # also, count uses each which always 'spams' (fortunately)
    end

=begin TAKES TOO LONG (18 seconds)
    should "create a non spamming thread for 'run'" do
      t1 = Time.now
      @input.run
      t2 = Time.now
      # on very slow computers spamming or not is the same and this
      # test will fail. Consider your machine to not be able to run this program anyway
      assert_operator(t2 - t1, :>=, 18.0)
    end
=end

    should "create 9 tracks with 985 events" do
      require_relative '../lib/rrts/node/chunk'
      chunk = Node::Chunk.new(@input)
      @input.run
      assert_equal(9, chunk.listing.count)
      assert_equal(985, chunk.count)
      assert_equal(985, chunk.count)
    end

    should "be able to run a spamming thread quickly" do
      t1 = Time.now
      @input.run
      # My measured time is 0.28 seconds
      assert_operator(Time.now - t1, :<=, 5.0)
    end
  end
end

class MidiFileWriterTest < Test::Unit::TestCase
  context 'writer' do
    setup do
      Node::Track::reset_key
      require_relative '../lib/rrts/node/midifilereader'
      @input = Node::MidiFileReader.new('fixtures/eurodance.midi', no_tampering: true,
                                        spam: true)
      require_relative '../lib/rrts/node/midifilewriter'
      @output = Node::MidiFileWriter.new('/tmp/t.midi', @input)
    end

    should "save MIDI exactly as being read" do
      @input.run
      `diff /tmp/t.midi fixtures/eurodance.midi`
      assert_equal(0, $?.exitstatus)
    end

    should "create something that can be read" do
      @input.run
      assert_equal(1767, Node::MidiFileReader.new('/tmp/t.midi').count)
    end
  end
end

class YamlWriterTest < Test::Unit::TestCase
  context 'yamlwriter' do
    setup do
      Node::Track::reset_key
      require_relative '../lib/rrts/node/midifilereader'
      @input = Node::MidiFileReader.new('fixtures/eurodance.midi', no_tampering: true, spam: true)
      require_relative '../lib/rrts/node/yamlwriter'
      @output = Node::YamlFileWriter.new('/tmp/t.yaml', @input)
    end

    should "save properly" do
      @input.run
      assert_match(/ASCII text/, `file --brief /tmp/t.yaml`.chomp)
      `diff /tmp/t.yaml fixtures/eurodance.yaml`
      assert_equal(0, $?.exitstatus)
    end

  end
end

class YamlReaderTest < Test::Unit::TestCase
  context 'yamlreader' do
    setup do
      Node::Track::reset_key
      require_relative '../lib/rrts/node/midifilereader'
      input = Node::MidiFileReader.new('fixtures/eurodance.midi', no_tampering: true, spam: true)
      require_relative '../lib/rrts/node/yamlwriter'
      filter = Node::YamlFileWriter.new('/tmp/t.yaml', input)
      input.run
      require_relative '../lib/rrts/node/yamlreader'
      @input = Node::YamlFileReader.new('/tmp/t.yaml', spam: true)
    end

    should "save properly" do
      file_del('/tmp/t2.yaml')
      assert(@input.consumers, 'consumers not set in producer')
      output = Node::YamlFileWriter.new('/tmp/t2.yaml', @input)
      @input.run
      assert(File.exists?('/tmp/t2.yaml'), 'YamlFileWriter dit not write (or close?) file')
      `diff /tmp/t.yaml /tmp/t2.yaml`
      assert_equal(0, $?.exitstatus)
    end

    should "have the same events as the midifilereader" do
      file_del('/tmp/t4.yaml')
      c0 = Node::MidiFileReader.new('fixtures/eurodance.midi', no_tampering: true, spam: true).count
      output = Node::YamlFileWriter.new('/tmp/t4.yaml', @input)
      @input.run
      assert(File.exists?('/tmp/t4.yaml'), 'YamlFileWriter dit not write (or close?) file')
      c1 = Node::MidiFileReader.new('fixtures/eurodance.midi', no_tampering: true, spam: true).count
      c2 = Node::YamlFileReader.new('/tmp/t4.yaml', spam: true).count
      assert_equal(1767, c1)
      assert_equal(1767, c2)
    end
  end
end

class IdentityTest < Test::Unit::TestCase
include RRTS

  context "identity" do
    setup do
      Node::Track::reset_key
    end

    should 'create 2 identical yaml files' do
#       tag "DELETE"
      file_del('/tmp/t6.midi', '/tmp/t5.yaml', '/tmp/t5.yaml')
      require_relative '../bin/node_identity'
      # Why does it not understand module Nodes here???
#       tag "create I 1"
#       trace do
      Nodes::I.new('--spam', '--input=fixtures/eurodance.midi',
                     '--output=/tmp/t6.midi', '--no-tampering').run
      assert(File::exists?('/tmp/t6.midi'))
#       end
#       tag "create I 2"
      Node::Track::reset_key
      Nodes::I.new('--spam', '--input=fixtures/eurodance.midi',
                   '--output=/tmp/t5.yaml', '--no-tampering').run
      assert(File::exists?('/tmp/t5.yaml'))
      Node::Track::reset_key

#       tag "create I 3"
      RRTS::Nodes::I.new('--spam', '--input=/tmp/t6.midi',
                   '--output=/tmp/t6.yaml', '--no-tampering').run
      assert(File::exists?('/tmp/t6.yaml'))
      `diff /tmp/t5.yaml /tmp/t6.yaml`
      assert_equal(0, $?.exitstatus)
#       tag "DONE TEST"
    end
  end
end

class SplitterTest < Test::Unit::TestCase
  context 'splitter' do
    setup do
#       tag "here!!!"
      require_relative '../lib/rrts/node/midifilereader'
      # ANY node is automatically a 'splitter'. Just connect
      # multiple consumers on top
      @input = Node::MidiFileReader.new('fixtures/eurodance.midi', spam: true)
#       require_relative '../lib/rrts/node/splitter'
#       @splitter = Node::Splitter.new(@input)
      # currently it is fuzzy about what should go in lib/rrts/node
      # and what is a script (like node_splitter.rb)
      # will be moved later then
    end

    should "be able to setup properly" do
    end

    should "be able to accept a filter" do
      filter = Node::Filter.new(@input) { |ev| ev.channel == 1 }
      require_relative '../lib/rrts/node/yamlwriter'
      Node::YamlFileWriter.new('/tmp/t7.yaml', filter)
      @input.run
      assert(File.exists?('/tmp/t7.yaml'))
    end

    should "be able to accept multiple filters" do
      filter = []
      filter << Node::Filter.new(@input) { |ev| ev.channel.nil? }
      (1..16).each do |i|
        # closures are super!  (But do NOT use a 'for' loop here (you will be sorry))
        filter << Node::Filter.new(@input) { |ev| ev.channel == i }
      end
      require_relative '../lib/rrts/node/yamlwriter'
      Node::YamlFileWriter.new('/tmp/chnil.yaml', filter[0])
      for i in 1..16
        Node::YamlFileWriter.new("/tmp/ch#{i}.yaml", filter[i])
      end
      @input.run
      assert(File.exists?('/tmp/chnil.yaml'))
      for i in 1..16
        `diff /tmp/ch#{i}.yaml fixtures/split/ch#{i}.yaml`
        assert_equal(0, $?.exitstatus)
      end
    end
  end # context
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
