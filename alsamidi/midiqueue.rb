#!/usr/bin/ruby1.9.1 -w
# encoding: utf-8

require_relative 'alsa_midi.so'
require 'forwardable'

module RRTS

  class MidiQueue
    include Comparable
    extend Forwardable

    private

=begin
    MidiQueue.new sequencer, name [, params] [, block]
    MidiQueue.new sequencer, id

    Parameters:
        sequencer - owner
        name - the name
        block - if passed the queue is auto-freed
        id - this returns a wrapper for the qid.
        params - allowed options:
           tempo - quarters per minute (int)
           tempo - or a Tempo

=end
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

    public

    # DO NOT USE
    attr :id

    # free
    def free
      return unless @id
      @seq_handle.free_queue @id
      @id = @seq_handle = @sequencer = nil
    end

    # tempo = Tempo
    def tempo= tmpo
      @seq_handle.set_queue_tempo @id, tmpo
    end

    # status
    def status
      @seq_handle.queue_status @id
    end

    # info
    def info
      @seq_handle.queue_info @id
    end

    # self start
    def start
      @seq_handle.start_queue @id
      self
    end

    # self stop
    def stop
      @seq_handle.stop_queue @id
      self
    end

    attr :sequencer
  end # MidiQueue

  class Tempo
    extend Forwardable
    private

=begin
     Tempo.new beats [,params]
     Tempo.new frames, smtp_timing: true [,params]
     Parameters:
         beats - quarters per minute
         smpte_timing - using frames, not beats
         ticks - overrides default of 384 for beats, or 40 for frames
=end

     Frames2TempoPPQ = { 24=>[500_000, 12], 25=>[400_000, 10], 29=>[100_000_000, 2997], 30=>[500_000, 15] }

     def initialize beats, params = nil
       frames = nil
       smpte_timing, ticks = false, 384
       if params
         for k, v in params
           case k
           when :smpte_timing
             smpte_timing, ticks = true, 40 if v
           when :ticks then ticks = v
           else raise RRTSError.new("illegal parameter '#{k}' for Tempo")
           end
         end
       end
       if smpte_timing
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
       @handle = snd_seq_queue_tempo_malloc
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

#      attr :ppq, :tempo, :beats, :frames  Can be done, but must make sure they stay in sync.
     # do we need it??

     def_delegators :@handle, :tempo=, :ppq=, :skew=, :skew_base=,
                              :tempo, :skew, :skew_base, :ppq
     def_delegator :@handle, :queue, :queue_id

  end  # Tempo
end # RRTS
