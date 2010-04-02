#!/usr/bin/ruby
=begin
     /> F4---------
  P1 -> F1\        \
  P2/      --> F3 -> C1
  P3 -> F2/       \> C2

3 threads:
P3->F2->F3->[C1,C2]  +  P2->F1->F3->[C1,C2]  +  P1->[F1->F3->[C1,C2],F4->C1]

=end

# DoLog = true
DoLog = false

require 'monitor'

class Node < Monitor
  private
  def initialize(name)
    super() # !
    @name = name
    @consumers = []
    @producercount = 0
  end

  # callback at end of consume (UGLY!!) Maybe we can use a lambna instead

  def each_fiber when_done = nil
    synchronize { @producercount += 1 }
    Fiber.new do |ev|
      begin
        loop do
          synchronize do
            if ev
              yield(ev)
            else
              STDERR.print "Stop consuming for #@name, count is now #{@producercount - 1}\n" if DoLog
              if (@producercount -= 1) == 0
                STDERR.print "raise StopIteration\n" if DoLog
                raise StopIteration
#                 break
#                 done
  #               return          ILLEGAL
  #               break # seems to jump out of synchronize.
              end
            end
          end
          STDERR.print "next yield\n" if DoLog
          ev = Fiber.yield
        end #loop
      ensure
        when_done.call if when_done
      end
    end
  end

  public

  # add an output, single Filter or Consumer,
  # or it can be an array of such. And we send to all.
  # You cannot use 'def >> *c' since  'x >> 3,4' is not valid ruby somehow, nor is x >> (3,4)
  # It should then be 'x.>>(3,4)' which is more ugly then x >> [3, 4]
  def >> connection
    connection = [connection] unless connection.respond_to?(:to_ary)
    # IMPORTANT, the 'consume' method CANNOT be applied here.
    # The reason is that the fibers must be created within the appropriate thread
    @consumers += connection.to_ary
    self
  end

  # override with something more usefull
  def consume
    each_fiber do |ev|
    end
    # ALERT!!! this code is executed BEFORE the loop and never after !!!
  end

  attr :name
end

class Producer < Node
  private
  def initialize name, *ary
    super(name)
    @ary = ary
  end

  public
  def each &block
    @ary.each &block
  end
#     return @ary.each unless block_given?
#     Thread.new do
      # this is now the actual reversed producer.
      # It can retrieve events from somewhere and then call yield
      # on them
#       @ary.each { |ev| yield(ev); sleep(rand + 0.2) }
#     end
#   end

  def produce
    Thread.new do
      # create consumer mapping
      consumers = @consumers.map{|out| [out.name, out.consume]}
      STDERR.print "#@name:: consumers = #{consumers.inspect}\n" if DoLog
      each do |ev|
        consumers.each do |name, out|
          STDERR.print "#@name::producing #{ev} and stashing to #{name} (RESUME)\n" if DoLog
          out.resume(ev)
        end
        sleep(rand + 0.2)
      end
      consumers.each do |name, out|
        STDERR.print "#@name::closing stream by stashing nil to #{name} (RESUME)\n" if DoLog
        out.resume(nil)
      end
    end
  end
end

class Consumer < Node

  def initialize name
    super
    @total = 0
    @producercount = 0
  end

#   def << event
#     STDERR.print "#@name::consume event=#{event})\n"
#     self
#   end

  # override
  def consume
=begin
    # a producer wants to write to us. Let's count him
    synchronize { @producercount += 1 }
    STDERR.print "#@name: start consumer, count is now #@producercount\n" if DoLog
    Fiber.new do |ev|
      STDERR.print "#@name: executing fiber ev=#{ev}\n" if DoLog
      loop do
        STDERR.print "#@name: YIELDED, mutex....\n" if DoLog
        synchronize do
          if ev
            STDERR.print "consumer #@name receives #{ev.inspect}, total:=#{@total+ev}\n" if DoLog
            @total += ev
          else
            STDERR.print "Stop consuming for #@name, count is now #{@producercount - 1}\n" if DoLog
            if (@producercount -= 1) == 0
              STDERR.print "Wow, #@name is done, total = #@total\n"
              break
            end
          end
        end
        STDERR.print "#@name: waiting for next event (==wait for resume)\n" if DoLog
        ev = Fiber.yield
      end
    end
=end
    each_fiber -> { STDERR.print "Wow, #@name is done, total = #@total\n" } do |ev|
      @total += ev
      STDERR.print "consumer #@name receives #{ev.inspect}, total:=#@total\n" if DoLog
    end
    # But code here is called BEFORE the loop starts, and never afterwards...
    # Still need a 'done' callback, which looks like a kludge
  end
end

class Filter < Node
  def initialize name, &block
    super(name)
    @condition = block # can be nil
    @producercount = 0
#     @consumercount = 0

  end

  #  Can be done the same as Node::consume but each_fiber is different!!!
  # It cannot bypass 'nil' as it needs to be sent further along the path!
  def consume
    STDERR.print "#@name: consume, returning fiber\n" if DoLog
    synchronize { @producercount += 1 }
#     @consumercount += 1
        # to calling thread
    consumers = @consumers.map{|out| [out.name, out.consume]} # this is more stable!
    # if placed in the fiber there is larger chance that a single prod-consumer
    # line is executed before another is started.
    # add consumer, send nil, add another consumer, send nil.
    # would result in two 'Wow' messages!
    Fiber.new do |ev|
      STDERR.print "#@name: exec fiber ev=#{ev.inspect}\n" if DoLog
      loop do
        STDERR.print "#@name: handle(#{ev.inspect}), mutex....\n" if DoLog
        synchronize do
          STDERR.print "#@name::in mutex\n" if DoLog
          if ev.nil? || !@condition || @condition.call(ev)
            consumers.each do |name, out|
              STDERR.print "#@name: pass on event #{ev.inspect} to #{name}, calling RESUME\n" if DoLog
              out.resume(ev)
            end
            break if ev.nil? && (@producercount -= 1) == 0
          else
            STDERR.print "#@name: DISCARDING #{ev.inspect}\n" if DoLog
          end
        end
        STDERR.print "#@name: blocking, waiting for yield\n" if DoLog
        ev = Fiber.yield # or break WRONG, must pass nil on!!
      end
#       consumers.each { |out| out.resume(nil) }  BAD
    end
  end
end

=begin the setup:

     /> F4{<=45}--------
  P1 -> F1{>45}\        \
  P2/         --> F3 -> C1
  P3 -> F2---/     \--> C2
=end
p1 = Producer.new('p1', 1, 1, 1, 1, 1000) #, 21, 31 )
p2 = Producer.new('p2', 10, 20, 10, 10) #, -2, 2)
p3 = Producer.new('p3', 100, 100, 100, 100)#, 23) #, 83, -13)
f1 = Filter.new('f1') { |x| x > 15 }
f2 = Filter.new('f2')
f3 = Filter.new('f3')
f4 = Filter.new('f4') { |x| x <= 15 }
c1 = Consumer.new('c1')
c2 = Consumer.new('c2')

#P3*->F2->F3->[C1,C2]  +  P2*->F1->F3  +  P1*->[F1,F4->C1]
p3>>(f2>>(f3>>[c1,c2]))
p2>>(f1>>f3)            # and note that F1 eats anything less than 46!!
p1>>[f1,f4>>c1]

=begin
threads = p1.produce, p2.produce, p3.produce
threads.map(&:join)

STDERR.puts "And now for something completely different:"
=end

srand
threads = [p1,p2,p3].map(&:produce)
# sleep(5)
STDERR.print("JOIN\n") if DoLog
threads.map(&:join)

# The correct answer is c1 -> 1420, and c2 -> 1424
=begin
Wow, c1 is done, total = 82
Wow, c2 is done, total = 82
Wow, c1 is done, total = 336
Wow, c2 is done, total = 336

double totals, and internally mixed up too?

The picture in top tells us something. c1 and c2 receive the very same events,
so their totals should in fact match. NO, since F4 only stores into c1...

Our outs are now split in a fiber for each generating thread. So I expect 6 results.
Well the other two are here, arriving earlier:
Wow, c1 is done, total = -20
Wow, c2 is done, total = -20

there are 3 threads, and they execute the following push-schema:
I)   P1->[F1->F3->[C1,C2],F4->C1]
II)  P2->F1->F3->[C1,C2]
III) P3->F2->F3->[C1,C2]

In the end they send a nil indicating end of input.
C1 has 4 consumerfibers. And C2 has three.

=end

