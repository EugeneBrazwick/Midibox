
module RRTS

  module Node
    # It would be nice if this could work like Enumerator
    # But currently 'Enumerator#peek' does not yet exists (probably ruby 1.9.2)
    # This can be fixed by caching the current element by next.
    # Also Enumerator does not work over threads and MT support might become
    # rather important.
    # We just import the interface then.
    # However, currently Enumerator IS being used through 'to_enum' obviously.

=begin rdoc
    A BaseTrack is an abstract baseclass for tracks. Basicly it is an enumerator,
    we just support each + next + peek

    Which is what makes it a node. A storage node.
=end
    class BaseTrack < EventsNode
      private
      def initialize
        @end_time = 0
      end

      @@key = 0

      public
      # either a single tick, or a real_time tuple [sec, nsec]
      attr_accessor :end_time

      def has_tracks?
        true
      end
    end

    # A track is a store for events. At most 16 channels are supported
    # and the track is tied to a single port/recording.
    # Tracks can contain meta information like voicename, portindex etc.
    class Track < BaseTrack
      include Enumerable
      private

      def initialize options = {}
        super()
        @events = []
        @key = @@key
        @@key += 1
        @sequencenr = @portindex = @voicename = nil
        # these may change as the track is recorded(!)
        # also do not manipulate the strings.
        # Some of these metaevent should become metaevents.
        # But I don't know how they are supposed to operate yet
        @copyright = @name = @intended_device = nil
        @combine_notes = @combine_progchanges = @combine_lsb_msb = true
        @channel = nil # if set, all events have this channel (range 0..16)
        for k, v in options
          case k
          when :combine_notes then @combine_notes = v
          when :combine_progchanges then @combine_progchanges = v
          when :combine_lsb_msb then @combine_lsb_msb = v
          when :tmpltrack, :template
            @sequencenr = v.sequencenr
            @copyright = v.copyright
            @portindex = v.portindex
            @voicename = v.voicename
            @name = v.name
          when :channel then @channel = v
          else
            raise RRTSError.new("invalid option '#{k}' for Track")
          end
        end
        rewind
        @open_notes = nil
      end

      def to_yaml_properties
        [:@copyright, :@name, :@intended_device, :@voicename, :@portindex,
         :@key, :@sequencenr, :@channel
        ]
      end

      # attempt to locate matching NoteOn event (with vel > 0)
      def handleNoteOff event
        if @open_notes && @open_notes[event.channel]
          j = @open_notes[event.channel][event.note]
          if j
            e = @events[j]
            @events[j] = NoteEvent.new(e.channel, e.note, e.velocity, duration: event.time_diff(e),
                                       off_velocity: event.velocity, tick: e.tick, track: e.track)
          else
            @events << event
          end
        else
          @events << event
        end
        self
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

      attr_accessor :copyright, :name, :intended_device
      # order in the original MIDI file ??
      attr_accessor :sequencenr
      # generated unique key per track (unique per process)
      attr :key
      attr_accessor :portindex, :channel

      # returns array of tracks, but if events is empty it returns []
      def listing
        if @events.empty? then [] else [self] end
      end

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
        last = @events.last
        raise RRTSError.new("bad timestamp for recorded event") if last && event.time_diff(last) < 0
        case event
        when ControllerEvent
          if @combine_lsb_msb
            msb = event.lsb2msb
            if msb
              if last && last.param == msb
  #               tag "merging msb #{last.param} with lsb #{event.param}, values are #{last.value} and #{event.value}"
                last.value = (last.value << 7) + event.value
                last.set_flag(coarse: false)
                return self
              end
            end
          elsif @combine_progchanges
            if event.param == :bank_lsb
              last = @events.last
              if ControllerEvent === last && e.param == :bank && last.flag(:coarse)
                last.value = [last.value, event.value]
                last.set_flag(coarse: false)
                return self
              end
            end
          end
        when NoteOnEvent
          if @combine_notes
            return handleNoteOff(event) if event.velocity == 0
            @open_notes ||= {}
            if @open_notes[event.channel]
              @open_notes[event.channel].delete(event.note)
            end
            (@open_notes[event.channel] ||= {})[event.note] = @events.length
          end
        when NoteOffEvent
          return handleNoteOff(event) if @combine_notes
        when ProgramChangeEvent
          if @combine_progchanges && !(Array === event.value)
            last = @events.last
            if ControllerEvent === last && last.param == :bank
              event.value = Array === last.value ? (last.value + [event.value]) : [last.value, event.value]
              @events.pop
            end
          end
        when LastEvent
          @open_notes = nil
        end
        if MidiEvent === event && !event.track
          raise StandardError.new("event #{event} has no track")
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
      def initialize first_track = nil, options = {}
        @split_tracks = true
        super()
        @tracks = []
        for k, v in options
          case k
          when :split_tracks then @split_tracks = v
          end
        end
        options.delete(:split_tracks)
        @track_options = options
        # keys are formatted as such: = "#{seqnr}:#{portnr}:#{channel}"
        @track_index = {} if @split_tracks
        self << first_track if first_track
        tag "CompoundTrack.new, split_tracks=#@split_tracks"
        # erm..... This is dangerous to cache. Can be done later
  #       @all_tracks = []
      end

      def track tmpltrack, channel
        key = "#{tmpltrack.key}:#{tmpltrack.portindex}:#{channel}"
        t = @track_index[key] and return t
        @track_options[:template] = tmpltrack
        @track_options[:channel] = channel
        @tracks << (t = @track_index[key] = Track.new(@track_options))
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
          # add a track
          @tracks << event
          @current_track = event
        else # it must be a real MidiEvent
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
        # @tracks is an ordinary array so this enumerates tracks
        @tracks.each(&:rewind)
      end

      # enumerates events, not tracks
      def each
        return to_enum unless block_given?
#         tag "each, self.next->#{p}"
        loop do
          p = self.next or break
          yield p
        end
        # locate the smallest event in any subtrack
      end

        # what about args ?
#       def to_enum using = :each, *args
#         using == :each ? self : super
#       end

      # an array of all contained tracks that actually have events
      def listing
        @tracks.inject([]) { |tot, track| tot.concat track.listing }
      end
    end # class CompoundTrack

  end # Node
end # RRTS