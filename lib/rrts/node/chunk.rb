
require_relative '../rrts'
require_relative 'track'
require 'forwardable'

module RRTS

  module Node
    # a Chunk has some meta information and contains a *single* track
    # but this may be a CompoundTrack
    # A chunk is an enumerable of events, but more importantly, it
    # has actual storage for events.
    class Chunk < EventsNode
      include Enumerable
      extend Forwardable
      MAJOR = true
      MINOR = false
      private
      def initialize options = {}
        @options = options
        require_relative '../midiqueue'
        @tempo = Tempo.new
        @time_signature = nil #  4, 4  do not set it! Otherwise saving/loading MIDI will have
        @clocks_per_beat = nil
            # differences.  Can be interpreted on other level if so required
        @key = nil # :C, MAJOR no default here
        @track = nil
      end
      public

      # the initial tempo (Tempo instance). Note this is an override from EventsNode
      attr_accessor :tempo

      attr_accessor :key, :time_signature, :clocks_per_beat
      # the internal track
      attr :track

      def ticks_per_beat= ppq
        @tempo.ppq = ppq
      end

#       def clocks_per_beat= cpb
#       end

      alias :ppq= :ticks_per_beat=

      # builder compatibilty
      def << event
        case event
        when BaseTrack
          if @track # aready exists
            if CompoundTrack === @track
              @track << event
            else
              @track = CompoundTrack.new(@track, @options)
            end
          elsif @options[:split_tracks]
            @track = CompoundTrack.new(event, @options)
          else
            @track = event
          end
          return self
        end
        @track << event
        self
      end

      def_delegators :@track, :each, :rewind, :next, :peek, :listing

      def has_tracks?
        true
      end
    end # class Chunk

  end # Node
end # RRTS