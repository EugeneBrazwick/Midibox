#!/usr/bin/ruby1.9.1 -w
# encoding: utf-8

require_relative 'alsa_midi.so'
require 'forwardable'

module RRTS

  # MidiQueue is required for scheduling events
  class MidiQueue
    include Comparable
    include Driver
    extend Forwardable

    private

#  This will allocate a 'named' queue
#  Parameters:
#  * [sequencer] owner
#  * [name] the name
#  * [block] if passed the queue is auto-freed
#  * [params] allowed options:
#       * [tempo] - quarters per minute (int) or a Tempo
    def initialize sequencer, name, params = nil
      @sequencer = sequencer
      @seq_handle = sequencer.instance_variable_get(:@handle)
      @id = @seq_handle.alloc_named_queue name
      begin
        tempo = nil
        if params
          for k, v in params
            case k
            when :tempo
              tempo = case v when Integer then Tempo.new(v) else v end
            else raise RRTSError.new("illegal parameter '#{k}' for MidiQueue")
            end
          end
        end
        self.tempo = tempo if tempo
        if block_given?
          begin
            yield self
          ensure
            free
          end
        end
      rescue
        free
        raise
      end
    end

    protected
    # DO NOT USE
    attr :id

    public

    # free the queue.
    def free
      return unless @id
      t, @seq_handle = @seq_handle, nil
      t.free_queue @id
      @id = @seq_handle = @sequencer = nil
    end

    # Parameters:
    # * [tmpo] Tempo instance
    def tempo= tmpo
      @seq_handle.set_queue_tempo @id, tmpo
    end

    # returns a AlsaQueueStatus_i instance
    def status
      @seq_handle.queue_status @id
    end

    # returns a AlsaQueueInfo_i instance
    def info
      @seq_handle.queue_info @id
    end

    def start
      @seq_handle.start_queue @id
      self
    end

    def stop
      @seq_handle.stop_queue @id
      self
    end

#     ConditionMap = {:input=>SND_SEQ_REMOVE_INPUT, :output=>SND_SEQ_REMOVE_OUTPUT,
#                     :dest=>SND_SEQ_R

#     Remove elements according to specification
#     With no arguments it removes all output events except NoteOffs.
#     Otherwise pass a bitset as expected by remove_events_set_condition
#     Or a hash with the following options:
#     - input: true
#     - output: true
#     - tag: string,  must match this tag
#     - time_before: time
#     - time_after: time
#     - time_ticks or ticks:  int. With exactly this 'tick' value
#     - dest_channel or channel: on this channel
#     - dest: on this destination port
#     - ignore_off: do NOT remove any NoteOffs.
#
#     A mix of options requires each one to be set. There is no constraint on options
#     that are not set. To remove all events pass 0 or {}.
#
#     Experimentation must confirm that NoteOn with velocity 0 is taken as a NoteOff.
    def clear events_to_remove = nil
      return unless @seq_handle
      cond = 0
      remove_ev = remove_events_malloc
      if Hash === events_to_remove
        for k, v in events_to_remove
          case k
          when :input then cond |= SND_SEQ_REMOVE_INPUT
          when :output then cond |= SND_SEQ_REMOVE_OUTPUT
          when :ignore_off then cond |= SND_SEQ_REMOVE_IGNORE_OFF
          when :dest_channel, :channel
            cond |= SND_SEQ_REMOVE_CHANNEL
            remove_ev.channel = v
          when :dest
            cond |= SND_SEQ_REMOVE_DEST
            remove_ev.dest = v
          when :time_before
            cond |= SND_SEQ_REMOVE_TIME_BEFORE
            remove_ev.time = v
          when :time_after
            cond |= SND_SEQ_REMOVE_TIME_AFTER
            remove_ev.time = v
          when :time_tick, :tick
            cond |= SND_SEQ_REMOVE_TIME_TICK
            remove_ev.time_tick = v
          when :tag_match, :tag
            cond |= SND_SEQ_REMOVE_TAG_MATCH
            remove_ev.tag = v
          else
            RAISE_MIDI_ERROR_FMT1("illegal option '#{k}' for clear")
          end
        end
      else
        cond = events_to_remove || (SND_SEQ_REMOVE_IGNORE_OFF | SND_SEQ_REMOVE_OUTPUT)
      end
      remove_ev.queue = @id
      remove_ev.condition = cond
      @seq_handle.remove_events remove_ev
    end

    alias :remove_events :clear
    attr :sequencer
  end # MidiQueue

  # Contains information about the speed
  # The following methods delegate:
  # * AlsaQueueTempo_i#skew
  # * AlsaQueueTempo_i#skew=
  # * AlsaQueueTempo_i#ppq
  # * AlsaQueueTempo_i#ppq=
  # * AlsaQueueTempo_i#skew_base
  # * AlsaQueueTempo_i#skew_base=
  # * AlsaQueueTempo_i#tempo
  # * AlsaQueueTempo_i#queue,  but this method is called queue_id here!!
  class Tempo
    extend Forwardable
    include Driver
    private

    Frames2TempoPPQ = { 24=>[500_000, 12], 25=>[400_000, 10], 29=>[100_000_000, 2997], 30=>[500_000, 15] }

#  Parameters:
#  * [beats] quarters per minute, defaults to 120. But with smpte_timing it is the framecount!
#  * [params] any of
#       * [:smpte_timing] using frames, not beats (quarters). Must be first!
#                         This is specifically for movie soundtracks as the tempo is
#                         tied to the number of frames (images) per second.
#                         If set, the +beats+ parameter is in fact the framecount.
#       * [:ticks] overrides the default of 384 for beats, or 40 for frames
#
# Example:
#     Tempo.new 25, smpte_timing: true
     def initialize beats = 120, params = nil
       frames = nil
       @smpte_timing, ticks = false, 384
       if params
         for k, v in params
           case k
           when :smpte_timing
             @smpte_timing, ticks = true, 40 if v
           when :ticks
             ticks = v
           when :ticks_per_quarter, :ticks_per_beat
             raise RRTSError.new("illegal parameter '#{k}' for Tempo") if @smpte_timing
             ticks = v
           when :ticks_per_frame
             raise RRTSError.new("illegal parameter '#{k}' for Tempo") unless @smpte_timing
             ticks = v
           else raise RRTSError.new("illegal parameter '#{k}' for Tempo")
           end
         end
       end
       if @smpte_timing
         frames, beats = beats, nil
         fail if frames > 255
         # ALSA doesn't know about the SMPTE time divisions, so
         # we pretend to have a musical tempo with the equivalent
         # number of ticks/s.
         (tempo, ppq = Frames2TempoPPQ[frames]) or fail
       else
         tempo = 60_000_000 / beats
         ppq = ticks
       end
       @handle = queue_tempo_malloc
       @handle.ppq = ppq
       @handle.tempo = tempo
     end

     def initialize_copy other
       @handle = other.copy_to_i
     end

     protected

#      attr :handle  DIRTY!

     def copy_to_i handle
       @handle.copy_to handle
     end

     public

     def_delegators :@handle, :tempo=, :ppq=, :skew=, :skew_base=,
                              :tempo, :skew, :skew_base, :ppq
     def_delegator :@handle, :queue, :queue_id

     # returns true is smptr_timing is set.
     def smpte_timing?
       @smpte_timing
     end
  end  # Tempo
end # RRTS
