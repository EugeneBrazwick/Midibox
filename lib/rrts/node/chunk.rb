
require_relative '../rrts'
require_relative 'track'
require 'forwardable'

module RRTS

  module Node
    # a Chunk has some meta information and contains a *single* track
    # but this may be a CompoundTrack
    # A chunk is an enumerable of events, but more importantly, it
    # has actual storage for events.
    class Chunk
      include Enumerable
      extend Forwardable
      MAJOR = true
      MINOR = false
      private
      def initialize split_tracks = false
        require_relative '../midiqueue'
        @split_tracks = split_tracks
        @tempo = Tempo.new
        @time_signature = 4, 4
        @key = :C, MAJOR
        @track = nil
      end
      public
      # the initial tempo (Tempo instance)
      attr_accessor :tempo, :key, :time_signature
      # the internal track
      attr :track

      def ticks_per_beat= ppq
        @tempo.ppq = ppq
      end

      alias :ppq= :ticks_per_beat=

      # builder compatibilty
      def << event
        case event
        when BaseTrack
          if @track # aready exists
            if CompoundTrack === @track
              @track << event
            else
              @track = CompoundTrack.new(@track, @split_tracks)
            end
          elsif @split_tracks
            @track = CompoundTrack.new(event, @split_tracks)
          else
            @track = event
          end
          return self
        end
        @track << event
        self
      end

      def_delegators :@track, :each, :rewind, :next, :peek
    end # class Chunk

  end # Node
end # RRTS