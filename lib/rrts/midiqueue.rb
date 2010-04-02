#!/usr/bin/ruby -w
# encoding: utf-8

require_relative 'driver/alsa_midi.so'
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
#                   or a hash suitable for #tempo=
#       * any option for the Tempo constructor
    def initialize sequencer, name, params = nil
      @sequencer = sequencer
      @seq_handle = sequencer.instance_variable_get(:@handle)
      @id = @seq_handle.alloc_named_queue name
      begin
        tempo = nil
        if params
          for k, v in params
#             tag "k=#{k}, v=#{v.inspect}"
            case k
            when :tempo
              tempo = case v when Integer then require_relative('tempo'); Tempo.new(v) else v end
            when :beats, :bpm, :qpm, :frames, :ticks, :ppq, :smpte_timing, :ticks_per_beat,
                 :ticks_per_frame, :ticks_per_quarter
              (tempo ||= {})[k] = v
            else raise RRTSError.new("illegal parameter '#{k}' for MidiQueue")
            end
          end
        end
#         tag "tempo=#{tempo.inspect}"
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

    public

    # DO NOT USE.  Used by rrecordmidi++ to identify a queue.
    attr :id

    # free the queue. If it is still running it is stopped first
    def free
      return unless @id
      stop if running?
      t, @seq_handle = @seq_handle, nil
      t.free_queue @id
      @id = @seq_handle = @sequencer = nil
    end

    # Assign a Tempo, or a hash containing :beats, :bpm, :qpm or :frames plus :ticks (optionally)
    # * [tmpo] Tempo instance, or a hash
    def tempo= tmpo
      if Hash === tmpo
#         tag "setting tempo to #{tmpo.inspect}"
        beats = tmpo[:beats] || tmpo[:bpm] || tmpo[:qpm] || tmpo[:frames]
        tmpo[:smpte_timing] = tmpo[:frames]
        tmpo.delete_if{|k,v| [:beats, :bpm, :qpm, :frames].include?(k) }
#         tag "beats=#{beats}, hash is now #{tmpo.inspect}"
        require_relative 'tempo'
        tmpo = Tempo.new beats, tmpo
      end
      @seq_handle.set_queue_tempo @id, tmpo
    end

    # returns a new AlsaQueueTempo_i instance, containing the tempo
    def tempo
      @seq_handle.queue_tempo @id
    end

    # returns a new AlsaQueueStatus_i instance, containing status information
    def status
      @seq_handle.queue_status @id
    end

    # returns a AlsaQueueInfo_i instance, containing queue information
    def info
      @seq_handle.queue_info @id
    end

    # start the queue. Returns self
    def start
#       puts "#{File.basename(__FILE__)}:#{__LINE__}:running? -> #{running?}"
      @seq_handle.start_queue @id
#       puts "#{File.basename(__FILE__)}:#{__LINE__}:Started. running? -> #{running?}"
      self
    end

    # stop the queue, returns self
    def stop
#       puts "#{File.basename(__FILE__)}:#{__LINE__}:running? -> #{running?}"
      @seq_handle.stop_queue @id
#       puts "#{File.basename(__FILE__)}:#{__LINE__}:Stopped, running? -> #{running?}"
      self
    end

    # is the client allowed to use it?
    def usage?
      @seq_handle.queue_usage? @id
    end

    # (dis)allow usage
    def usage= bool
      @seq_handle.queue_usage = bool
    end

    # returns true if the queue has been started
    # *Important*: there is a delay. Presumably because events are send out and
    # only on receiving these the state is actually changed.
    # So this method is slightly unreliable
    def running?
#       puts "#{File.basename(__FILE__)}:#{__LINE__}:status.status=#{status.status}"
      @id && status.status != 0
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

    # short for status.tick_time
    def tick_time
      status.tick_time
    end

    # short for status.real_time
    def real_time
      status.real_time
    end
  end # MidiQueue

end # RRTS
