
module RRTS

  module Node
    # It would be nice if this could work like Enumerator
    # But currently 'Enumerator#peek' does not yet exists (probably ruby 1.9.2)
    # This can be fixed by caching the current element by next.
    # Also Enumerator does not work over threads and MT support might become
    # rather important.
    # We just import the interface then

=begin rdoc
    A BaseTrack is an abstract baseclass for tracks. Basicly it is an enumerator,
    we just support each + next + peek
=end
    class BaseTrack
      private
      def initialize
        @end_time = 0
      end

      @@key = 0

      public
      # either a single tick, or a real_time tuple [sec, nsec]
      attr_accessor :end_time
    end

    # A track is a store for events. At most 16 channels are supported
    # and the track is tied to a single port/recording.
    # Tracks can contain meta information like voicename, portindex etc.
    class Track < BaseTrack
      include Enumerable
      private

      def initialize
        super
        @events = []
        rewind
        @key = @@key
        @@key += 1
        @sequencenr = 0
        @portindex = 0
        # these may change as the track is recorded(!)
        # also do not manipulate the strings.
        # Some of these metaevent should become metaevents.
        # But I don't know how they are supposed to operate yet
        @description = @copyright = @name = @voicename = @lyrics = @marker = ''
        @cue_point = ''
        @channel = nil # if set, all events have this channel (range 0..16)
      end

      public

#       def self.sequencenr
#         @@sequencenr
#       end
#
#       def self.inc_sequencenr
#         r = @@sequencenr
#         @@sequencenr += 1
#         r
#       end

      # access to the Array of MidiEvent instances
      attr :events

      attr_accessor :description, :copyright, :name, :voicename, :lyrics,
                    :marker, :cue_point
      # order in the original MIDI file
      attr_accessor :sequencenr
      attr :key
      attr_accessor :portindex, :channel

      # returns the 'next' event to be enumerated, or nil if EOT was reached
      def peek
        @events[@ptr]
      end

      def next
        r = @events[@ptr]
        raise StopIteration.new unless r
        @ptr += 1
        r
      end

      def rewind
        @ptr = 0
      end

      def << event
        if ControllerEvent === event
          msb = event.lsb2msb
          if msb
            last = @events.last
            if last && last.param == msb
#               tag "merging msb #{last.param} with lsb #{event.param}, values are #{last.value} and #{event.value}"
              last.value = (last.value << 7) + event.value
              last.set_flag(coarse: false)
              return self
            end
          end
        end
        @events << event
        # this could alter it:
        event.track = self
      end

      def each &block
        @events.each(&block)
      end
    end

=begin rdoc
    A compoundTrack does *not* contain events immediately, but it does
    contain other tracks
=end
    class CompoundTrack < BaseTrack
      include Enumerable
      private
      def initialize first_track = nil, split_tracks = false
        super()
        @tracks, @split_tracks = [], split_tracks
        # keys are formatted as such: = "#{seqnr}:#{portnr}:#{channel}"
        @track_index = {} if @split_tracks
        self << first_track if first_track
        # erm..... This is dangerous to cache. Can be done later
  #       @all_tracks = []
      end

      def track tmpltrack, channel
        key = "#{tmpltrack.key}:#{tmpltrack.portindex}:#{channel}"
        t = @track_index[key] and return t
        @tracks << (t = @track_index[key] = Track.new)
        t.sequencenr = tmpltrack.sequencenr
        t.copyright = tmpltrack.copyright
        t.portindex = tmpltrack.portindex
        t.description = tmpltrack.description
        t.voicename = tmpltrack.voicename
        t.name = tmpltrack.name
        t.portindex = tmpltrack.portindex
        t.channel = channel
        t
      end

      # this is not entirely accurate
      public
  #     def end_time= tm
  #       @tracks.each {|track| track.end_time = tm }
  #     endd

      # store an event or track in the current track
      def << event
        if BaseTrack === event
          @tracks << event
          @current_track = event
        else
          if @split_tracks
            track(event.track, event.channel) << event
          else
            @current_track << event
          end
        end
      end

      # returns the smallest event in any of our tracks
      def peek
        l = nil
        for t in @tracks
          p = t.peek or next  # NOTE: this is always the keyword 'next'!
          l = p if !l || p < l
        end
        l
      end

      def next
        l = mint = nil
        for t in @tracks
          p = t.peek or next  # NOTE: this is always the keyword 'next'!
          if !l || p < l
            l = p
            mint = t
          end
        end
        raise StopIteration.new unless mint
        mint.next
        l
      end

      def rewind
        @tracks.each(&:rewind)
      end

      def each
        return to_enum unless block_given?
#         tag "each, self.next->#{p}"
        loop do
          p = self.next or break
          yield p
        end
        # locate the smallest event in any subtrack
      end

    end # class CompoundTrack
  end # Node
end # RRTS