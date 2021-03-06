#!/usr/bin/ruby -w

require_relative 'driver/alsa_midi.so'
require 'forwardable'

module RRTS

  # Contains information about the speed
  # The following delegates exist:
  # Driver::AlsaQueueTempo_i#skew
  # Driver::AlsaQueueTempo_i#skew=
  # Driver::AlsaQueueTempo_i#ppq
  # Driver::AlsaQueueTempo_i#ppq=
  # Driver::AlsaQueueTempo_i#skew_base
  # Driver::AlsaQueueTempo_i#skew_base=
  # Driver::AlsaQueueTempo_i#tempo
  # Driver::AlsaQueueTempo_i#queue,  but this method is called queue_id here!!
  class Tempo
    extend Forwardable
    include Driver
    private

    Frames2TempoPPQ = { 24=>[500_000, 12], 25=>[400_000, 10], 29=>[100_000_000, 2997], 30=>[500_000, 15] }

#   Parameters:
#   [beats] quarters per minute, defaults to 120. But with smpte_timing it is the framecount!
#   [params] any of
#            [:smpte_timing] using frames, not beats (quarters). Must be first!
#                            This is specifically for movie soundtracks as the tempo is
#                            tied to the number of frames (images) per second.
#                            If set, the +beats+ parameter is in fact the framecount.
#            [:ticks] overrides the default of 384 for beats, or 40 for frames
#            [:skew] ?
#            [:skew_base] ?
#  Example:
#      Tempo.new 25, smpte_timing: true
     def initialize beats = 120, params = nil
       frames = nil
       @smpte_timing, ticks = false, 384
       skew = skew_base = nil
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
           when :skew then skew = v
           when :skew_base then skew_base = v
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
         (tempo, mult = Frames2TempoPPQ[@frames]) or raise RRTSError.new("illegal framecount #@frames")
         @ticks_per_frame = ticks
         ppq = mult * ticks # per frame
       else
         tempo = 60_000_000 / beats
         ppq = ticks
       end
       @handle = queue_tempo_malloc
       @handle.ppq = ppq
       @handle.tempo = tempo
       @handle.skew = skew if skew
       @handle.skew_base = skew_base if skew_base
     end

     def initialize_copy other
       @handle = other.copy_to_i
     end

     protected

#      attr :handle  DIRTY!

     # used by initialize_copy
     def copy_to_i handle
       @handle.copy_to handle
     end

     public

     def_delegators :@handle, :tempo=, :ppq=, :skew=, :skew_base=,
                              :tempo, :skew, :skew_base, :ppq
     def_delegator :@handle, :queue, :queue_id

     # returns true is smpte_timing is set.
     def smpte_timing?
       @smpte_timing
     end

     # override, yaml cannot dump handles
     def to_yaml opts = {}
       hash = {:smpte_timing=>@smpte_timing, :ppq=>@handle.ppq,
#                :tempo=>@handle.tempo,
               :skew=>@handle.skew, :skew_base=>@handle.skew_base}
       if @smpte_timing
         hash[:ticks_per_frame] = @ticks_per_frame
         hash[:frames] = @frames
       else
         hash[:beats] = 60_000_000 / @handle.tempo
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

     # pulses (ticks) per second
     def pps
       @smpte_timing ? @ticks_per_frame * @frames : @handle.ppq * 1_000_000 / @handle.tempo
     end

     alias :usecs_per_beat :tempo
  end  # Tempo
end # RRTS
