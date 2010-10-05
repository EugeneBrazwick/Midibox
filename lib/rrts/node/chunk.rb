
require_relative '../rrts'
require_relative 'track'
require 'forwardable'

module RRTS

=begin SOME THOUGHTS

Sending non events to nodes is probably bad.
Instead of sending a track to a chunk we could sent a meta event like
CreateTrackEvent.
=end

  module Node
# a Chunk has some meta information and contains a *single* track
# but this may be a CompoundTrack
# A chunk is an enumerable of events, but more importantly, it
# has actual storage for events.
#
# The following methods delegate to @track:
# - rewind, Reset the track, and/or all subtracks
# - each. Chunks can be treated as eventservers
# - next. Return the next event. The first time called (or after rewind)
#   it returns the first event. If the track is a compound track
#   it returns the event with smallest timestamp and priority
# - peek. Return the same event as next but without changing the track position
# - listing. Return a flat array with all contained tracks
#
# A chunk can also be used as a consumer.
    class Chunk < Producer
      extend Forwardable
      # constant for setting the key
      MAJOR = true
      # constant for setting the key
      # It is possible to change the key using a KeySignatureEvent
      MINOR = false
      private
      # Option used is _split_channels_ to record each channel on its
      # own track. This does not merge tracks, even if they share a channel
      # All other options are passed on to the track
      # However, a track is only created when the first event is send
      def initialize producer = nil, options = nil
        @split_channels = false
        @options = options # for creating tracks
#         require_relative '../tempo'
        @tempo = nil # similar, should be taken as 'Tempo.new'
        @time_signature = nil #  4, 4  do not set it! Otherwise saving/loading MIDI will result in
                              # differences.  Can be interpreted on other level if so required
        @clocks_per_beat = nil
        @key = nil # :C, MAJOR no default here
        @track = nil
        @track_index = {} # hash indexed by key, contains all tracks within the chunk.
        super(options)
        # track remain empty until the first event is sent (using <<)
        producer >> self if producer
      end

      def parse_option k, v
        case k
        when :split_tracks, :split_channels then @split_channels = v
        when :combine_lsb_msb, :combine_notes, :combine_progchanges
        else super
        end
      end

      public

      def to_yaml_properties
        [:@tempo, :@time_signature, :@clocks_per_beat, :@key, :@track]
      end

      # the initial tempo (Tempo instance). Note this is an override from EventsNode
      attr_accessor :tempo

      # the key is a tuple like [:C, MAJOR]
      # the time signature is a tuple like [4,4]
      # clocks_per_beat is typically 24
      # These values may change during recording(!)
      attr_accessor :key, :time_signature, :clocks_per_beat
      # the internal track, normally a CompoundTrack
      attr :track
      # a hash indexed by Track#key. Also a flat list of all tracks.
      # it is maintained as tracks are added using <<.
      attr :track_index

      # Sets the ticks per beat. Tempochanges later on are possible
      # by sending a TempoEvent
      def ticks_per_beat= ppq
        @tempo.ppq = ppq
      end

      # ppq == pulses per quarter, same as ticks per beat
      alias :ppq= :ticks_per_beat=

      def consume producer, &when_done
        if chunk = producer.chunk
          # clone it (by reference even)
          @split_channels = chunk.split_channels
          @options = chunk.options    # to pass to CompoundTrack
          @tempo = chunk.tempo
          @time_signature = chunk.time_signature
          @clocks_per_beat = chunk.clocks_per_beat
          @key = chunk.key # :C, MAJOR no default here
          @track = chunk.track
          @track_index = chunk.track_index
          when_done.call if when_done
          return nil
        end
        each_fiber(when_done) do |event|
#           tag "Chunk receives event #{event}"
          case event
          when ChunkCreateEvent
            @split_channels = event.split_channels
            @options = { :combine_lsb_msb=>event.combine_lsb_msb,
                         :combine_notes=>event.combine_notes,
                         :combine_progchanges=>event.combine_progchanges,
                         :split_channels=>@split_channels}
#             tag "ChunkCreateEvent received, options is now #{@options.inspect}"
            event = nil # cannot store this event, there is no track yet
          when TrackCreateEvent
#             tag "CREATE TRACK, options=#{@options.inspect}"
            track = Track.new(@options)
#             tag "HERE"
            @track_index[track.key] = track
            if @track # aready exists
              unless CompoundTrack === @track
                @track = CompoundTrack.new(@track, @options)
                event = nil
                # currently, compound tracks have no key
#                 @track_index[@track.key] = @track
              end
            elsif @split_channels
              @track = CompoundTrack.new(track, @options)
              event = nil
#               @track_index[@track.key] = @track
            else
              @track = track
              event = nil
            end
          when TimeSignatureEvent
            @time_signature = event.time_signature
            @clocks_per_beat = event.clocks_per_beat
          when KeySignatureEvent
            @key = event.key_signature
          when TempoEvent
            if Tempo === (t = event.tempo) # NOT usecs_per_beat
              @tempo = t
            else
              raise RTTSError, 'no tempo available' unless @tempo
              # don't know if you get the correct result if only usecs_per_beat is known
              @tempo.tempo = t
            end
            # sometimes arrives when there is not yet a track made
            event = nil unless @track
          when ControllerEvent
#             tag "received: #{event}"
          end
#           tag "event=#{event.inspect}"
          @track << event if event
        end
      end

      def_delegators :@track, :each, :rewind, :next, :peek, :listing

      # Are tracks supported, or only events? Always true for Chunk.
      def has_tracks?
        true
      end

      # recreate track.events (after being loaded) as empty array
      def fix_tracks
        @track.fix
        @track_index = {}
#         tag "track=#{@track.inspect}"
#         tag "listing = #{@track.listing}"
        for track in @track.listing(true) # allow empty!
          @track_index[track.key] = track
        end
      end

      # return the designated track from the index. Event should be received
      # from a yaml stream where it lost its track reference.
      def track_for(event)
#         case event.track
#         when BaseTrack then
        @track_index[event.track] or raise RRTSError.new("Track #{event.track} could not be located, keys=#{@track_index.keys.inspect}")
#         else event.track
#         end
      end

      def to_chunk
        self
      end
    end # class Chunk

  end # Node
end # RRTS