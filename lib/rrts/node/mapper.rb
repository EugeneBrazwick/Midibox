#!/usr/bin/ruby -w

require_relative 'node'

module RRTS
  module Node

=begin

Problems: TempoEvent misery.  Even if one sequencer is in use, the first
event it receives depends completely on the pipelining.  So some events must
be designated using InternalEvent or so.  These events are then never subjected
to filtering so we need not to worry about them.
=end

=begin rdoc
Mapper is a filter (and its filter can be set using the +condition+ option)
where you can pass an event mapper method.  It receives a copy of the original
event, and may change that freely, then it must call +super+, to send the
event to all registered receivers.

In using it you would probably like to include a filter condition. For example you
can reroute events by changing channel. However, the ProgChanges on the original
channel will also be passed.
=end
    class Mapper < Filter
      private
      # create a new mapper. A condition lambda could be passed within options.
      # See Filter#new
      def initialize producer = nil, options = nil, &mapper
#         tag "Mapper.new"
        @mapper = mapper
#         tag "Calling super WITHOUT mapper"
#         super(producer, options)  it DOES send mapper!!!!
        super(producer, options) { |ev| true }
      end

      # override
      def handle_event ev, cons
        @mapper.call(ev = ev.dup) # if the event is frozen clone will not unfreeze it
        super
      end

    end # class Mapper

  end # Node
end # RTTS

if __FILE__ == $0
  include RRTS
  include Node
  require_relative 'recorder'
  require_relative 'player'
  # It is VERY important to use 1 sequencer. Otherwise the queues are out of sync, or
  # so it seems. It seems that flush does not work correctly. But it can also be a bug.
  # To enforce that, set client_name.
  recorder = Recorder.new('20:0', client_name: 'mapper')
 #=begin
  mapper = Mapper.new(recorder,
                      condition: lambda do |ev|
                        case ev
                       # UGLY (FIXME) must pass TempoEvent or Player breaks down
                        when NoteOnOffEvent, QueueEvent then true
                        else false
                        end
                      end ) do |ev|
    # default E-80 uses channel 4 for main output (where 1 is the first and 16 the last)
#     puts "MAP #{ev}"
    ev.channel = 6 if ev.channel == 4  # can also be nil for sysex
  end
 #=end
  # the player bypasses mapper as well, so basicly recorder events are split
  player = Player.new('20:1', [recorder, mapper], client_name: 'mapper')
  begin
    recorder.run
  rescue Interrupt
  end
end