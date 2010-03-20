#!/usr/bin/ruby -w
# encoding: utf-8

require_relative 'driver/alsa_midi.so'
require 'forwardable'

module RRTS

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
           when :ticks_per_quarter, :ticks_per_beat, :ppq
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
         @frames, beats = beats, nil
         fail if @frames > 255
         # ALSA doesn't know about the SMPTE time divisions, so
         # we pretend to have a musical tempo with the equivalent
         # number of ticks/s.
         (tempo, mult = Frames2TempoPPQ[@frames]) or fail
         @ticks_per_frame = ticks
         ppq = mult * ticks # per frame
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

     def to_yaml opts = {}
       hash = {:smpte_timing=>@smpte_timing, :ppq=>@handle.ppq, :tempo=>@handle.tempo,
               :skew=>@handle.skew, :skew_base=>@handle.skew_base}
       if @smpte_timing
         hash[:ticks_per_frame] = @ticks_per_frame
         hash[:frames] = @frames
       end
       hash.to_yaml(opts)
     end

     # how tempo is stored in a midi file (two bytes)
     def time_division
       if @smpte_timing
         @ticks_per_frame | ((0x100 - @frames) << 8)
       else
         @handle.ppq
       end
     end
  end  # Tempo
end # RRTS
