
require_relative 'node'

module RRTS

  module Node
    # It would be nice if this could work like Enumerator
    # But currently 'Enumerator#peek' does not yet exists (probably ruby 1.9.2)
    # This can be fixed by caching the current element by next.
    # We just import the interface then.

#     A BaseTrack is an abstract baseclass for tracks. Tracks are Producers that
#     use actual storage for events.
#     They should also be consumers and filters but this is not implemented yet.
#     Currently useless anyway.
    class BaseTrack < Producer
      private
        def initialize options = nil
          super #!
          @end_time = 0
        end

        @@key = 1

      public
        # either a single tick, or a real_time tuple [sec, nsec]
        attr_accessor :end_time

        # tracks support tracks, so always true
        def has_tracks?
          true
        end
    end

    # A track is a store for events. At most 16 channels are supported
    # and the track is tied to a single port/recording.
    # At least, for now, as these restrictions seem stupid.
    # Tracks can contain meta information like voicename, portindex etc.
    class Track < BaseTrack
      include Enumerable
      private

# Setup an empty track. Supported options are:
# - combine_notes, create NoteEvent from NoteOn + NoteOff
# - combine_progchanges, create extended program changes that include the bank selection
# - combine_lsb_msb, create control14 events (but just as ControllerEvent)
# - tmpltrack or template: create a split track from a source track. Copies
#        the copyright notice, the sequencernr, portindex, voicename and the trackname.
        def initialize options = nil
  #         tag "Track.new"
          @events = []
          @sequencenr = @portindex = @voicename = nil
          # these may change as the track is recorded(!)
          # also do not manipulate the strings.
          # Some of these metaevent should become metaevents.
          # But I don't know how they are supposed to operate yet
          @copyright = @name = @intended_device = nil
          @combine_notes = @combine_progchanges = @combine_lsb_msb = true
          @channel = nil # if set, all events have this channel (range 0..16)
          @key = nil
          super
  #         tag "HERE"
          @key = Track.allocate_key unless @key
  #         tag "Track.new, options=#{options.inspect}, self=#{self.inspect}"
          rewind
          @open_notes = nil
  #         tag "CONSTRUCTED"
        end

        def parse_option k, v
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
          when :split_channels # ignore
          else
            tag "Unrecognized option #{k} ?"
            super
          end
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

        def self.allocate_key
          r = nil
          Thread.exclusive do
            r = @@key
            @@key += 1
          end
          r
        end

        def self.reset_key
          @@key = 1
        end

        # access to the Array of MidiEvent instances
        attr :events

        # name of the voice for this track, must be given through metadata
        attr :voicename

        # the track can be given a name,
        # intended_device is the device that is the target, since a lot of midievents
        # are devicedependent
        attr :copyright, :name, :intended_device

        # order in the original MIDI file ??
        attr :sequencenr

        # generated unique key per track (unique per process)
        attr :key

        # the portindex is a relative indicator, and not a portid. For example, you
        # might have read from 3 ports to create the chunk.
        # channel is the channel recorded from, but may also be the target channel.
        attr :portindex, :channel

        # returns array of tracks, but if events is empty it returns []
        def listing(allow_empty = false)
          if !allow_empty && @events.empty? then [] else [self] end
        end

        # returns the 'next' event to be enumerated, or nil if EOT was reached
        def peek
          @events[@ptr]
        end

        # returns the next event (ordered by time and priority)
        # the first call (or after a rewind) returns the first event
        def next
          r = @events[@ptr]
          raise StopIteration.new unless r
          @ptr += 1
          r
        end

        # reset the track pointer to 0
        def rewind
          @ptr = 0
        end

        def fix
          @events = []
          rewind
        end

        # record an event in the track. Builder interface
        # FIXME: the conversions here require a separate filter as this is out of place!
        def << event
          last = @events.last
          raise RRTSError, "bad timestamp for recorded event" if last && event.time_diff(last) < 0
          case event
          when ControllerEvent
            if ControllerEvent === last
              if @combine_lsb_msb
                # This assumes the MSB is sent first
    #             tag "attempt to combine_lsb_msb"
                msb = event.lsb2msb
                if msb && last.param == msb
    #                 tag "merging msb #{last.param} with lsb #{event.param}, values are #{last.value} and #{event.value}"
                  last.value = (last.value << 7) + event.value
                  last.set_flag(coarse: false)
                  return self
                end
              elsif @combine_progchanges && event.param == :bank_lsb &&
                    last.param == :bank && last.flag(:coarse)
                # combine lsb + msb specifically for banks, even if combine_lsb_msb is false
                last.value = [last.value, event.value]
                last.set_flag(coarse: false)
                return self
              end
            end
          when NoteOnEvent
            if @combine_notes
              return handleNoteOff(event) if event.velocity == 0
              @open_notes ||= {}
              @open_notes[event.channel].delete(event.note) if @open_notes[event.channel]
              (@open_notes[event.channel] ||= {})[event.note] = @events.length
            end
          when NoteOffEvent
            return handleNoteOff(event) if @combine_notes
          when ProgramChangeEvent
            if @combine_progchanges && !(Array === event.value) &&
                ControllerEvent === last && last.param == :bank
              event.value = Array === last.value ? (last.value + [event.value])
                                                : [last.value, event.value]
              @events.pop
            end
          when LastEvent
            @open_notes = nil
            @end_time = event.time
          when TrackPortIndexEvent
            @portindex = event.portindex
          when TrackIntendedDeviceEvent
            @intended_device = event.intended_device
          end
          @events << event
          event.track = self
        end

        # each is delegated to the events array
        def each &block
          @events.each(&block)
        end
    end

#     A compoundTrack does *not* contain events immediately, but it does
#     contain other tracks
    class CompoundTrack < BaseTrack
      include Enumerable
      private
#   create a new compound track, optionally inserting the first track
#   Option recognized is
#   - split_channels (default true). If set events are shifted on channel as well as on
#         original track.
#   All other options are passed to the created tracks (as caused by _split_channels_)
        def initialize first_track = nil, options = nil
          @split_channels = false # since pretty useless after all
          super(options)
          @tracks = []
          options.delete(:split_channels)
          @track_options = options
          @current_track = first_track
          # keys are formatted as such: = "#{seqnr}:#{portnr}:#{channel}"
          @track_index = {} if @split_channels
          @tracks << first_track if first_track
          # erm..... This is dangerous to cache. Can be done later
    #       @all_tracks = []
        end

        def parse_option k, v
          case k
          when :split_tracks, :split_channels then @split_channels = v
          when :combine_lsb_msb, :combine_notes, :combine_progchanges
              # ignored since it already is stored in @track_options
          else super
          end
        end

        # used by channel splitter, create a track for the channel (using tmpltrack
        # as a template) or return an already created track.
        def track tmpltrack, channel
          key = "#{tmpltrack.key}:#{tmpltrack.portindex}:#{channel}"
          t = @track_index[key] and return t
          @track_options[:template] = tmpltrack
          @track_options[:channel] = channel
          @tracks << (t = @track_index[key] = Track.new(@track_options))
          t
        end

      public
  #     def end_time= tm
  #       @tracks.each {|track| track.end_time = tm }
  #     endd

        # store an event in the current track. Builder interface. slightly out of tune
        def << event
          if TrackCreateEvent === event
            # add a track
            track = Track.new
            @tracks << track
            @current_track = track
          else # it must be a real MidiEvent
  #           tag "adding midievent, split_channels= #@split_channels"
            if @split_channels
              track(@current_track, event.channel) << event
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

        # returns the next event in sequence, selecting it from any subtrack
        # available
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

        # reset the track pointer for all subtracks (recursively)
        def rewind
          # @tracks is an ordinary array so this enumerates tracks
          @tracks.each(&:rewind)
        end

        # enumerates events, not tracks
        def each
          return to_enum unless block_given?
          rewind # !
  #         tag "each, self.next->#{p}"
          loop do
            # locate the smallest event in any subtrack
            p = self.next or break
            yield p
          end
        end

          # what about args ?
  #       def to_enum using = :each, *args
  #         using == :each ? self : super
  #       end

        # a flat array of all contained tracks that actually have events
        def listing(allow_empty = false)
          @tracks.inject([]) do |tot, track|
  #           tag "tot=#{tot}, track=#{track}, key=#{track.key}, result=#{tot + track.listing}"
            tot + track.listing(allow_empty)
          end
        end

        # fix after reading yamldata. Currently unused since reading no longer uses tracks
        def fix
          # tracks is just an array
  #         tag "fix"
          @tracks.each(&:fix)
  #         tag "fixed"
        end
    end # class CompoundTrack

  end # Node
end # RRTS