#!/usr/bin/ruby1.9.1 -w

require_relative 'driver/alsa_midi.so'
require 'forwardable'
require_relative 'rrts'

module RRTS

  # forward
  class Tempo; end

# MidiEvent can be used to read, write and manipulate MIDI events.
#
# To create an event you would normally use Sequencer#event_input but to
# synthesize events MidiEvent::new can be used
  class MidiEvent
    include Driver, Comparable

    private

      # if there are more synonyms the first one will be returned normally when reading events.
      # used in debunkparam_i, a callback from AlsaSequencer_i#event_output
      Symbol2Param = {
        :bank=>MIDI_CTL_MSB_BANK, :bank_select=>MIDI_CTL_MSB_BANK, #0
        :bank_lsb=>MIDI_CTL_LSB_BANK,
        :modwheel=>MIDI_CTL_MSB_MODWHEEL, #1
        :modwheel_lsb=>MIDI_CTL_LSB_MODWHEEL,
        :modulation_wheel=>MIDI_CTL_MSB_MODWHEEL,
        :breath=>MIDI_CTL_MSB_BREATH, :breath_controller=>MIDI_CTL_MSB_BREATH, #2
        :breath_lsb=>MIDI_CTL_LSB_BREATH,
        :foot=>MIDI_CTL_MSB_FOOT, :foot_pedal=>MIDI_CTL_MSB_FOOT, #4
        :foot_lsb=>MIDI_CTL_LSB_FOOT,
        :portamento_time=>MIDI_CTL_MSB_PORTAMENTO_TIME, #5
        :portamento_time_lsb=>MIDI_CTL_LSB_PORTAMENTO_TIME,
        # data_entry applies to the last (un)registered parameter
        :data_entry=>MIDI_CTL_MSB_DATA_ENTRY, #6
        :data_entry_lsb=>MIDI_CTL_LSB_DATA_ENTRY,
        :volume=>MIDI_CTL_MSB_MAIN_VOLUME, :main_volume=>MIDI_CTL_MSB_MAIN_VOLUME, #7
        :volume_lsb=>MIDI_CTL_LSB_MAIN_VOLUME,
        :balance=>MIDI_CTL_MSB_BALANCE, #8
        :balance_lsb=>MIDI_CTL_LSB_BALANCE,
        :pan=>MIDI_CTL_MSB_PAN, :pan_position=>MIDI_CTL_MSB_PAN, #10
        :pan_lsb=>MIDI_CTL_LSB_PAN,
        :expression=>MIDI_CTL_MSB_EXPRESSION, #11
        :expression_lsb=>MIDI_CTL_LSB_EXPRESSION,
        :sustain=>MIDI_CTL_SUSTAIN, :hold_pedal=>MIDI_CTL_SUSTAIN, :hold=>MIDI_CTL_SUSTAIN, #64
        :portamento=>MIDI_CTL_PORTAMENTO, #65
        :sostenuto=>MIDI_CTL_SOSTENUTO,#66
        :soft=>MIDI_CTL_SOFT_PEDAL, :soft_pedal=>MIDI_CTL_SOFT_PEDAL, #67
        :legato=>MIDI_CTL_LEGATO_FOOTSWITCH, :legato_footswitch=>MIDI_CTL_LEGATO_FOOTSWITCH,#68
        :hold2=>MIDI_CTL_HOLD2, :hold2_pedal=>MIDI_CTL_HOLD2,#69
        :sound_variation=>MIDI_CTL_SC1_SOUND_VARIATION,#70
        :timbre=>MIDI_CTL_SC2_TIMBRE,#71
        :release=>MIDI_CTL_SC3_RELEASE_TIME, :release_time=>MIDI_CTL_SC3_RELEASE_TIME, #72
        :attack=>MIDI_CTL_SC4_ATTACK_TIME, :attack_time=>MIDI_CTL_SC4_ATTACK_TIME, #73
        :brightness=>MIDI_CTL_SC5_BRIGHTNESS, #74
        :sc6=>MIDI_CTL_SC6, :sc7=>MIDI_CTL_SC7, :sc8=>MIDI_CTL_SC8, :sc9=>MIDI_CTL_SC9,
        :sc10=>MIDI_CTL_SC10,
        :reverb=>MIDI_CTL_E1_REVERB_DEPTH, #91
        :tremolo=>MIDI_CTL_E2_TREMOLO_DEPTH,#92
        :chorus=>MIDI_CTL_E3_CHORUS_DEPTH,#93
        :detune=>MIDI_CTL_E4_DETUNE_DEPTH, :celeste=>MIDI_CTL_E4_DETUNE_DEPTH, #94
        :phaser=>MIDI_CTL_E5_PHASER_DEPTH,#95
        # data_inc works on last (un)registered parameter that passed along
        :data_increment=>MIDI_CTL_DATA_INCREMENT,#96
        :data_decrement=>MIDI_CTL_DATA_DECREMENT,#97
        :reset_controllers=>MIDI_CTL_RESET_CONTROLLERS, #121
        :all_controllers_off=>MIDI_CTL_RESET_CONTROLLERS, #121
        :all_notes_off=>MIDI_CTL_ALL_NOTES_OFF, #123
        :all_sounds_off=>MIDI_CTL_ALL_SOUNDS_OFF, :panic=>MIDI_CTL_ALL_SOUNDS_OFF,#120
        :omni_off=>MIDI_CTL_OMNI_OFF, :omni_on=>MIDI_CTL_OMNI_ON,#124,#125
        :mono=>MIDI_CTL_MONO1,#126
        :poly=>MIDI_CTL_MONO2,  #127 ??
        :general_purpose1=>MIDI_CTL_MSB_GENERAL_PURPOSE1,
        :general_purpose2=>MIDI_CTL_MSB_GENERAL_PURPOSE2,
        :general_purpose3=>MIDI_CTL_MSB_GENERAL_PURPOSE3,
        :general_purpose4=>MIDI_CTL_MSB_GENERAL_PURPOSE4,
        :general_purpose1_lsb=>MIDI_CTL_LSB_GENERAL_PURPOSE1,
        :general_purpose2_lsb=>MIDI_CTL_LSB_GENERAL_PURPOSE2,
        :general_purpose3_lsb=>MIDI_CTL_LSB_GENERAL_PURPOSE3,
        :general_purpose4_lsb=>MIDI_CTL_LSB_GENERAL_PURPOSE4,
        :general_purpose5=>MIDI_CTL_GENERAL_PURPOSE5,
        :general_purpose6=>MIDI_CTL_GENERAL_PURPOSE6,
        :general_purpose7=>MIDI_CTL_GENERAL_PURPOSE7,
        :general_purpose8=>MIDI_CTL_GENERAL_PURPOSE8,
        :portamento_control=>MIDI_CTL_PORTAMENTO_CONTROL,
        :nonreg_parm_num=>MIDI_CTL_NONREG_PARM_NUM_MSB,
        # AKA: RPN
        :regist_parm_num=>MIDI_CTL_REGIST_PARM_NUM_MSB,
        # note that LSB is in fact send first here!!!! At least that's what arecordmidi.c does
        # the following is a list of registered parameters
        #  0 = pitchbend range  MSB == semitones,  LSB = cents
        #  1 = master fine tuning   14 bit data in cents where 0x2000 is a440
        #  2 = coarse tuning        14 bit semitones where 0x40 = a440
        #  0x3fff = unset any 'current' RPN
        # My MIDI reference says that MSB can be send before LSB. Even in this case.
        # IMPORTANT: since these are controller events the value is in fact the RPN (and not param)
        # they set the RPN and then following data_entry and data_increment and data_decrement
        # messages will all effect this parameter.
        :nonreg_parm_num_lsb=>MIDI_CTL_NONREG_PARM_NUM_LSB,
        :regist_parm_num_lsb=>MIDI_CTL_REGIST_PARM_NUM_LSB
        }

      DEFAULT_FLAGS = { :time_mode_absolute=>true, :time_mode_ticks=>true } # cow!

=begin
    IMPORTANT: all events must support this way of construction
    new Sequencer, AlsaMidiEvent_i
    new typesymbol [,...]
=end

# call-seq:  new(typeid [, params = nil]) -> MidiEvent
#
# This constructor should not be called directly, as this is an abstract class.
#
# Parameters:
# [typeid] for internal use
# [params] can be any of the following keys, plus a value
#         [:value] the +value+ as interpreted by the class of event. For notes this
#                  is the note.
#         [:channel] in range 1..16
#         [:duration] only for NoteEvent. Should be compatible with the timemode set
#         [:velocity], in range 0..127
#         [:off_velocity] speed with which the note was released
#         [:source] the port that sent or will send the event
#         [:sender] same as +source+
#         [:dest] the port that will receive or received the event
#         [:destination] same as +dest+
#         [:sender_queue] the midi queue to use for sending, as opposed to +queue+
#         [:tick] the time the event occured, or should occur
#         [:time] same as +tick+. Use this name for realtime queues
#         [:queue] as subject of this event (specific for QueueEvent.
#         [:time_mode_tick]  boolean to set the timemode to ticks
#         [:time_mode_real] set the timemode to realtime
#         [:time_mode_relative] set the timemode relative (to the queuetime ?)
#         [:time_mode_absolute] timestamps are absolute
#         [:coarse] indicates that the value passed should be send as single 7 bit value
#                   and the event should not be split automatically
#         [:param] the parameter for ControllerEvent end the like. In that case +value+
#                  is in fact the real parameter! And the value follows using :data_entry
#                  messages
#         [:track] Higher level ownership of the event
#         [:direct] If true then there is no queueing, nor timing and the event is sent
#                   immediately without buffering
      def initialize arg0, arg1 = nil
        @flags = DEFAULT_FLAGS
        case arg1
        when AlsaMidiEvent_i # input_event handling
        arg1.populate(arg0, self) # See alsa_midi++.cpp
          #       puts "called populate, @type=#@type, type=#{type}"
        else # result of user construction
          @type = arg0 or raise RRTSError.new("illegal type man!!")
          # Don't use flags, as it seems rather costly using a hash here.
          @channel = nil # OK
          @velocity = @value = @param = @source = @track = nil
          # @dest = @queue = nil  used???
          # @off_velocity = @duration = hardly ever used
          @time = nil
  #         puts "#{File.basename(__FILE__)}:#{__LINE__}:@tick:=nil"
          arg1.each { |k, v| parse_option k, v } if arg1
        end
        raise RTTSError, "internal error, no flags" unless @flags
      end

      def parse_option k, v
        case k
        when :value then @value = v
        when :channel
          #RTTSError.new("illegal channel #{v}") unless v.between?(1, 16)
          # can be a range or maybe even an array of channels!!
          # or an array of ranges... ???
          @channel = v
  #             tag "channel:=#@channel"
        when :duration then @duration = v
        when :velocity then @velocity = v
        when :off_velocity then @off_velocity = v
        when :source, :sender
          @source = v
        when :dest, :destination then @dest = v
        when :sender_queue
          @sender_queue = v # LEAVE THE HACKING to alsa_midi_event yes please... .respond_to(:id) ? v.id : v
        when :tick, :time
          @time = v
  #             puts "#{File.basename(__FILE__)}:#{__LINE__}:@tick:=#{v}"
        when :queue
          @queue = v
        when :time_mode_tick then set_flag(time_mode_tick: v, time_mode_real: !v)
        when :time_mode_real then set_flag(time_mode_tick: !v, time_mode_real: v)
        when :time_mode_relative
          set_flag(time_mode_relative: v, time_mode_absolute: !v)
        when :time_mode_absolute
          set_flag(time_mode_relative: !v, time_mode_absolute: v)
        when :coarse
          if v && @value && @value > 0x7f  # this is not waterproof
            raise RRTSError, "overflowing coarse controller value[#{arg1[:param]}] #{arg1[:value]}"
          end
          set_flag(coarse: v)
        when :param then @param = v
        when :track then @track = v
        when :direct then @sender_queue = @time = nil # bit of a hack...
        else raise RRTSError.new("illegal option '#{k}' for #{self.class}")
        end
      end

      # returns tuple [param_id, coarse_b]
      # coarse_b should be true if we need to send a single event.
      # otherwise an MSB + LSB should both be send
      def debunkparam_i
  #       tag "param = #{@param.inspect}, event = #{self}, flags=#{@flags.inspect}"
        if Symbol === @param
          p = Symbol2Param[@param] or raise RRTSError.new("Bad paramname '#@param'")
          return p, @flags[:coarse]
        end
        return @param, @flags[:coarse]
      end

      Flag2IntMap = {
                      :time_mode_real=>SND_SEQ_TIME_STAMP_REAL,
                      :time_real=>SND_SEQ_TIME_STAMP_REAL,
                      :time_mode_ticks=>SND_SEQ_TIME_STAMP_TICK,
                      :time_mode_tick=>SND_SEQ_TIME_STAMP_TICK,
                      :time_ticks=>SND_SEQ_TIME_STAMP_TICK,
                      :time_tick=>SND_SEQ_TIME_STAMP_TICK,
                      :time_mode_relative=>SND_SEQ_TIME_MODE_REL,
                      :time_mode_absolute=>SND_SEQ_TIME_MODE_ABS,
                      :time_relative=>SND_SEQ_TIME_MODE_REL,
                      :time_absolute=>SND_SEQ_TIME_MODE_ABS
                    }
      Type2IntMap = { :noteon=>SND_SEQ_EVENT_NOTEON, # 6
                      :noteoff=>SND_SEQ_EVENT_NOTEOFF, #7
                      :note=>SND_SEQ_EVENT_NOTE, # 5
                      :keypress=>SND_SEQ_EVENT_KEYPRESS, # 8
                      :controller=>SND_SEQ_EVENT_CONTROLLER, #10
                      :control14=>SND_SEQ_EVENT_CONTROL14,  # ALSA?? 14 bit controller
                      :pgmchange=>SND_SEQ_EVENT_PGMCHANGE, #11
                      :pitchbend=>SND_SEQ_EVENT_PITCHBEND, #13
                      :chanpress=>SND_SEQ_EVENT_CHANPRESS, #12
                      :songpos=>SND_SEQ_EVENT_SONGPOS, #20
                      :songsel=>SND_SEQ_EVENT_SONGSEL, #21
                      :sysex=>SND_SEQ_EVENT_SYSEX, #130
                      :start=>SND_SEQ_EVENT_START, #30
                      :stop=>SND_SEQ_EVENT_STOP, #32
                      :continue=>SND_SEQ_EVENT_CONTINUE, #31
                      :clock=>SND_SEQ_EVENT_CLOCK,#36
                      :tick=>SND_SEQ_EVENT_TICK, #37
                      :setpos_tick=>SND_SEQ_EVENT_SETPOS_TICK, #33
                      :setpos_time=>SND_SEQ_EVENT_SETPOS_TIME,#34
                      :syncpos=>SND_SEQ_EVENT_SYNC_POS,#39
                      :sync_pos=>SND_SEQ_EVENT_SYNC_POS,#39
                      :tempo=>SND_SEQ_EVENT_TEMPO, #35
                      :queue_skew=>SND_SEQ_EVENT_QUEUE_SKEW, #38
                      :skew=>SND_SEQ_EVENT_QUEUE_SKEW, #38
                      :tune_request=>SND_SEQ_EVENT_TUNE_REQUEST,#40
                      :reset=>SND_SEQ_EVENT_RESET, #41
                      :sensing=>SND_SEQ_EVENT_SENSING, #42
                      :echo=>SND_SEQ_EVENT_ECHO, #50
                      :port_subscribed=>SND_SEQ_EVENT_PORT_SUBSCRIBED,
                      :port_unsubscribed=>SND_SEQ_EVENT_PORT_UNSUBSCRIBED,
                      :port_start=>SND_SEQ_EVENT_PORT_START,
                      :port_exit=>SND_SEQ_EVENT_PORT_EXIT,
                      :port_change=>SND_SEQ_EVENT_PORT_CHANGE,
                      :oss=>SND_SEQ_EVENT_OSS,
                      :none=>SND_SEQ_EVENT_NONE,
                      :client_start=>SND_SEQ_EVENT_CLIENT_START,
                      :client_exit=>SND_SEQ_EVENT_CLIENT_EXIT,
                      :client_change=>SND_SEQ_EVENT_CLIENT_CHANGE,
                      :system=>SND_SEQ_EVENT_SYSTEM,
                      :result=>SND_SEQ_EVENT_RESULT,
                      :bounce=>SND_SEQ_EVENT_BOUNCE,
                      :usr0=>SND_SEQ_EVENT_USR0,
                      :usr1=>SND_SEQ_EVENT_USR1,
                      :usr2=>SND_SEQ_EVENT_USR2,
                      :usr3=>SND_SEQ_EVENT_USR3,
                      :usr4=>SND_SEQ_EVENT_USR4,
                      :usr5=>SND_SEQ_EVENT_USR5,
                      :usr6=>SND_SEQ_EVENT_USR6,
                      :usr7=>SND_SEQ_EVENT_USR7,
                      :usr8=>SND_SEQ_EVENT_USR8,
                      :usr9=>SND_SEQ_EVENT_USR9,
                      :usr_var0=>SND_SEQ_EVENT_USR_VAR0,
                      :usr_var1=>SND_SEQ_EVENT_USR_VAR1,
                      :usr_var2=>SND_SEQ_EVENT_USR_VAR2,
                      :usr_var3=>SND_SEQ_EVENT_USR_VAR3,
                      :usr_var4=>SND_SEQ_EVENT_USR_VAR4
                      }
      # returns [type, flags] as two integers from the current @type and @flags
      def debunktypeflags_i
  #       puts "#{File.basename(__FILE__)}:#{__LINE__}:debunktypeflags_i"
        if @flags
          flags = 0
          for k, v in @flags
            v and f = Flag2IntMap[k] and flags |= f
          end
        else
          flags = SND_SEQ_TIME_MODE_ABS | SND_SEQ_TIME_STAMP_TICK
          # this should match DEFAULT_FLAGS!!
        end
        type = Type2IntMap[@type] or raise RRTSError.new("internal error: no mapping for :#{@type}")
  #       puts "returning [#{type}, #{flags}], type=#@type"
        return type, flags
      end

    public

=begin :no-doc:
    # the typeid, a symbol equal to the suffix of the event name in lower case
    # Examples: :start, :sensing, :pgmchange, :noteon
    # DO NOT USE. It is redundant!!
=end
      attr :type # :no-doc:

      # timestamp of event, either in ticks (int) or realtime [secs, nanosecs]
      attr_accessor :time
      alias :tick :time
      alias :tick= :time=

      # The source MidiPort, also called the _sender_
      attr_accessor :source
      alias :sender :source
      alias :sender= :source=

      # The destination MidiPort
      attr_accessor :dest

      # Track that stores this event (not neccesarily the source)
      attr_accessor :track

      # test for a flag. If more than one is given, all must be set.
      # the following keys are understood:
      # [:time_mode_real], for +SND_SEQ_TIME_STAMP_REAL+
      # [:time_real], for +SND_SEQ_TIME_STAMP_REAL+
      # [:time_mode_ticks] for +SND_SEQ_TIME_STAMP_TICK+
      # [:time_mode_tick] for +SND_SEQ_TIME_STAMP_TICK+
      # [:time_tick] for +SND_SEQ_TIME_STAMP_TICK+
      # [:time_ticks] preffered alias for +time_tick+
      # [:time_mode_relative] for +SND_SEQ_TIME_MODE_REL+
      # [:time_mode_absolute] for +SND_SEQ_TIME_MODE_ABS+
      # [:time_relative] for +SND_SEQ_TIME_MODE_REL+
      # [:time_absolute] for +SND_SEQ_TIME_MODE_ABS+
      def flag *keys
        for k in keys
          return false unless @flags[k]
        end
        true
      end

      # see MidiEvent#flag
      def set_flag hash
        @flags = @flags.dup if @flags.equal?(DEFAULT_FLAGS)
        for k, v in hash
          @flags[k] = v
        end
        self
      end

      # the MidiQueue used for sending, if both queue and time are unset we use +direct+ events
      attr_accessor :sender_queue

      # receiver queue. id or MidiQueue
      attr :receiver_queue

      # notes and control events have a channel. We use the range 1..16
      # The channel can be set to an enumerable. This will make the
      # messages be sent to all the given channels
      attr_accessor :channel

      # notes have this
      attr_accessor :velocity

      # for NoteEvent (which is not a MIDI event) specific
      attr :off_velocity

      # for NoteEvent specific
      attr_accessor :duration

      # can be 'event' for result messages, but normally used for controls
      attr :param

      # value is a note or a control-value, a result-value, or a queue-value, also a sysex binary string
      # normally it would be an integer
      # Can be ticks for queues, time for queues, or a [skew, skew_base] tuple
      # Can be a MidiPort for port message, and a MidiClient for client messages
      # It is legal to pass notenames as strings like 'C#5' or 'Bb3'. [A-Ga-g](#|b)?[0-9]
      # When retrieved they will be integers though.
      attr_accessor :value

      # queue: the queue (id or MidiQueue) of a queue control message
      attr_accessor :queue

      # these are MidiPorts for connection events
      attr :connnect_sender, :connect_dest

      # two events are 'the same' if the time and priority is the same. In other words
      # if you sort them this will be on time. The priority depends on the class of MidiEvents
      # a 'bank select' event and a 'note' event on the same time should be taken in that
      # order, as it is obvious that we must change the voice first. See controller events
      # have a lower priority index (indicating a *higher* priority). 0 is the highest
      # priority
      def <=> other
  #       tag "<=>"
        d = @time <=> other.time
  #       tag "compared times -> #{d}, time=#@time, other.time=#{other.time}"
        return d if d != 0
  #       tag "prio=#{priority}, other.prio=#{other.priority}"
        priority <=> other.priority
      end

      # returns the time difference (self - other)
      # The events must have compatible timestamps.
      def time_diff other
        otime = MidiEvent === other ? other.time : other
        if Array === @time
          d = 1_000_000_000 * (@time[0] - otime[0]) + @time[1] - otime[1]
          [ d / 1_000_000_000, d % 1_000_000_000 ]
        else
          @time - otime
        end
      end

      # returns the event time increased with delta. Delta must have a compatible type
      def time_plus delta
        if Array === @time
          d = 1_000_000_000 * (@time[0] - delta[0]) + @time[1] - delta[1]
          [ d / 1_000_000_000, d % 1_000_000_000 ]
        else
          @time + delta
        end
      end

      # lower is more important, used for sorting events with equal time
      def priority
        0
      end

      # this ruins the event... But we may be able to recover from it...
      # Some types are problematic, in particular any class from the Driver library.
      def to_yaml *args
        if instance_variable_defined?(:@track) # don't wake the sleeping dog
          @track = @track.key if @track.respond_to?(:key)
        end
        if instance_variable_defined?(:@dest)
          @dest = @dest.address if @dest.respond_to?(:address)
        end
        if instance_variable_defined?(:@source)
          @source = @source.address if @source.respond_to?(:address)
        end
        if instance_variable_defined?(:@queue)
          @queue = @queue.id if @queue.respond_to?(:id)
        end
        if instance_variable_defined?(:@value)
          case @value
          when AlsaQueueTempo_i
            @value = @value.tempo
          end
        end
        super
      end

      class FlagHelper
        private
          def initialize event
            @event = event
          end

        public

          def [](*f)
            @event.flag(*f)
          end

          def []=(f, val)
            @event.set_flag(f=>val)
          end
      end

      # flags[x]      :== flag(x)
      # flags[x,y]    :== flag(x, y)
      # flags[x] = v  :== set_flag(x=>v)
      def flags
        FlagHelper.new(self)
      end

      # the default midi status nibble
      def status
        0x0
      end
  end  # MidiEvent

  # a VoiceEvent has a channel (arg0), and also a value (arg1) (could be 'note')
  # This is an abstract class.
  class VoiceEvent < MidiEvent
    private
      # :call-seq: new(type, channel, value, [, params = nil]) -> VoiceEvent
      def initialize arg0, arg1 = nil, value = nil, params = nil
        case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
        else
          super arg0, params
          @value = value
          @channel = arg1
        end
      end
  end

  # convenience class for filtering
  class NoteOnOffEvent < VoiceEvent
  end

  # A NOTEON event
  class NoteOnEvent < NoteOnOffEvent

    private
    # new(sequencer, event)
    # new(channel, note, velocity [,...])

      # Parameters:
      # [channel] in range 1..16
      # [note] 0..127 but it is allowed to use strings like 'C4' or 'd#5' or 'Eb6'
      # [velocity] 0..127
      def initialize channel, note = nil, velocity = nil, params = nil
        case note when AlsaMidiEvent_i then super(channel, note)
        else
          super :noteon, channel, note, params
          @velocity = velocity
        end
      end

    public

      # for debugging purposes mostly
      def to_s
        "NoteOnEvent[#@time] ch:#@channel, #@value, vel:#@velocity"
      end

      alias :note :value

      # REALLY low
      def priority
        990
      end

      def status
        0x9
      end
  end

  # Keypress or aftertouch event
  class KeypressEvent < NoteOnOffEvent
    private

      # Parameters:
      # [channel] 1..16
      # [note] 0..127 but it is allowed to use strings like 'C4' or 'd5' or 'Eb6'
      # [velocity] 0..127
      def initialize channel, note = nil, velocity = nil, params = nil
        case note when AlsaMidiEvent_i then super(channel, note)
        else
          super :keypress, channel, note, params
          @velocity = velocity
        end
      end

      public

      def priority
        995
      end

      alias :note :value
      alias :pressure :velocity

      def status
        0xa
      end
  end

  # alias for KeypressEvent
  KeyPressEvent = KeypressEvent

  # noteoff event
  class NoteOffEvent < NoteOnOffEvent
    private

      # Parameters:
      # [channel] 1..16
      # [note] 0..127 or a string like 'C4' or 'd5' or 'Eb6'
      def initialize channel, note = nil, params = nil
        @off_velocity = 0 # as default
        case note when AlsaMidiEvent_i then super(channel, note)
        else
          super :noteoff, channel, note, params
        end
      end

    public

      def priority
        999
      end

      def status
        0x8
      end

      alias :note :value

      def to_s
        "NoteOffEvent ch:#@channel, #@value"
      end
  end

  # an Alsa hack. NoteEvents can never be received on realtime input, since it
  # would require blocking the NoteOnEvents. Currently the only node producing
  # them is Chunk.
  class NoteEvent < NoteOnOffEvent
    private
      # :call-seq: new(channel, note, velocity [, params - nil ]) -> NoteEvent
      # +duration+ must be set using a named parameter. Same for +off_velocity+.
      # Parameters:
      # [channel] 1..16
      # [note]  It is allowed to use strings like 'C4' or 'd5' or 'Eb6'
      # [velocity] The 'on' velocity only
      # [params] Normally you want to set:
      #         [:duration] in time compatible with the input or output
      #         [:off_velocity] by default this is set to 0 if missing
      def initialize arg0, arg1 = nil, velocity = nil, params = nil
        @off_velocity = 0
        case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
        else
          super :note, arg0, arg1, params
          @velocity = velocity
        end
      end

    public
      def priority
        995
      end

      alias :note :value

      def to_s
        "NoteEvent ch:#@channel, #@value, vel:#@velocity, duration:#@duration"
      end

      def off_time
        time_plus(@duration)
      end
  end

  # the controller event class represents in reality a large group of more specific events
  # Each having a parameter denoting the kind of event, and value where appropriate
  # Currently all values are unsigned, but I may still change this (probably even)
  class ControllerEvent < VoiceEvent

    private
      # IMPORTANT: if you use a controller-parameter that requires an on/off value
      # then 0 is off and 64 is on. You can use the constants below as well.
      # Or you pass 'false' or 'true' for value.
      ON = 0x40
      OFF = 0x0

#     *IMPORTANT*: all events must support this way of construction
#     arg0 is a Sequencer, arg1 is a LOW LEVEL AlsaMidiEvent_i.
#     new sequencer, event

# *IMPORTANT*: the value you pass here may be a 14 bits int, or else 2 7 bit ints
# as in [MSB,LSB]
# this depends on the param.
# Two events will actually be sent.
# Pass coarse: false to use the value as a single 7 bits int
# if one of the _lsb params is used the controller will have a 7 bits value
# In both cases only one event is sent.
#
# 'param' can be a symbol from:
# - :bank_select (14 bits), or better 7+7
# - :modulation_wheel (14)
# - :breath_controller (14)
# - :foot_pedal (14)
# - :portamento_time (14)
# - :data_entry (14)
# - :volume (14)
# - :balance (14)                  as in MONO, this just makes L or R stronger
# - :pan(14)  POSITIVE    as in STEREO, this places the source elsewhere (virtually)
# - :expression(14)
# - :general_purpose 1 to 4
#
# or any from these, which are 1 bit (a boolean):
# - :hold_pedal,
# - :portamento,
# - :sustenuto,
# - :soft,
# - :legato
# - :hold_2_pedal.
# Note that value 'ON' (bit 7) is used for this.
# IMPORTANT: passing '1' here does therefore not activate the control!
# But 'true' can be passed safely
#
# and these are also valid params, all unsigned 7 bits:
# - :timbre,
# - :release,
# - :attack,
# - :brightness,
# - :effects_level,
# - :tremulo_level/:tremulo,
# - :chorus_level/:chorus,
# - :celest_level/:celeste/:detune
# - :phaser
# - :general_purpose 5 to 8 (??)
#
# These are 0 bits:
# - :all_controllers_off (single channel)
# - :all_notes_off (nonlocal, except pedal)
# - :all_sound_off/:panic (nonlocal)
# - :omni_off,
# - :omni_on,
# - :mono,
# - :poly
#
# Finally it is possible that the paramnumber itself is a 14 bit unsigned int.
# Use :nonreg_parm_num and :regist_parm_num for this. I believe 'registered' means
# it is reserved by some company.
# It is also possible to pass a tuple as 'value'.
#   ControllerEvent.new channel, :bank_select, [1, 23]
#   This would select bank 1*128+23.    BROKEN???
      def initialize channel, param = nil, value = 0, params = nil
        case param when AlsaMidiEvent_i
          super(channel, param)
        else
          params, value = value, 0 if Hash === value
          (params ||= {})[:param] = Driver::param2sym(param)
          super :controller, channel, value, params
        end
      end

    public
      alias :program :value

      def status
        0xb
      end

      def to_s
        "ControllerEvent[#@time] ch:#@channel, param: #@param -> #@value"
      end

      LSB2MSB = { :bank_lsb=>:bank, :modwheel_lsb=>:modwheel, :breath_lsb=>:breath,
                  :foot_lsb=>:foot, :portamento_time_lsb=>:portamento_time,
                  :data_entry_lsb=>:data_entry, :volume_lsb=>:volume,
                  :balance_lsb=>:balance, :pan_lsb=>:pan, :expression_lsb=>:expression,
                  :general_purpose1_lsb=>:general_purpose1,
                  :general_purpose2_lsb=>:general_purpose2,
                  :general_purpose3_lsb=>:general_purpose3,
                  :general_purpose4_lsb=>:general_purpose4,
                  :nonreg_parm_num_lsb=>:nonreg_parm_num,
                  :regist_parm_num_lsb=>:regist_parm_num
                }
      MSB2LSB = LSB2MSB.invert

      # returns msb param symbol, if this is an lsb param, otherwise nil
      def lsb2msb
        LSB2MSB[Symbol === @param ? @param : Driver::param2sym(@param)]
      end

      # returns lsb param symbol, if this is an msb param and nil otherwise
      def msb2lsb
        MSB2LSB[Symbol === @param ? @param : Driver::param2sym(@param)]
      end

      # you can treat it as a boolean as well
      alias :lsb? :lsb2msb

      # you can treat it as a boolean as well
      alias :msb? :msb2lsb
  end # class ControllerEvent

  # Control14Event = ControllerEvent  BAD IDEA, there is no such thing

  # PRGCHANGE events
  class ProgramChangeEvent < VoiceEvent
    private
=begin
    IMPORTANT: all events must support this way of construction
    arg0 is a Sequencer, arg1 is a LOW LEVEL AlsaMidiEvent_i.
    new sequencer, event
=end
      # Parameters:
      # [channel] 1..16
      # [program] can be a single value in range 0..127.
      #           Or it may be a tuple [bank_msb, progno]
      #           Or even [bank_msb, bank_lsb, progno]
      #           The last one will of course send 3 events when sent.
      def initialize channel, program = nil, params = nil
        case program when AlsaMidiEvent_i then super(channel, program)
        else
          super :pgmchange, channel, program, params
        end
      end

    public
      # program can be a single value in range 0..127.
      # Or it may be a tuple [bank_msb, progno]
      # Or even [bank_msb, bank_lsb, progno]
      alias :program :value

      def status
        0xc
      end

      def to_s
        "ProgramChangeEvent ch:#@channel, program: #{program.inspect}"
      end

      def priority
        1
      end

  end

  # to bend the pitch (and who does not want to do that)
  class PitchbendEvent < VoiceEvent
    private
  # Parameters:
  # [channel] 1..16
  # [value] a 14 bits signed integer in the range -0x2000 to 0x2000 (FIXME)
  # [params] See MidiEvent::new
      def initialize channel, value = nil, params = nil
        case value when AlsaMidiEvent_i then super(channel, value)
        else
          super :pitchbend, channel, value, params
        end
      end

    public

      def status
        0xe
      end
  end

  # another alias
  PitchBendEvent = PitchbendEvent

  # channel pressure == poor man's aftertouch
  class ChannelPressureEvent < VoiceEvent
    private
      # new Sequencer, event

      # call-seq: new(channel, pressure [,params = nil]) -> ChannelPressureEvent
      # Pressure should be in the range 0..127
      def initialize arg0, arg1 = nil, params = nil
        case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
        else
          super :chanpress, arg0, arg1, params
        end
      end

    public

      def status
        0xd
      end

  end

  # has a channel ????  FIXME ??
  class SongPositionEvent < VoiceEvent
    private
      def initialize arg0, arg1 = nil, params = nil
        case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
        else
          super :songpos, arg0, arg1, params
        end
      end
  end

  # has a channel ????  FIXME ??
  class SongSelectionEvent < VoiceEvent
    private
      def initialize arg0, arg1 = nil, params = nil
        case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
        else
          super :songsel, arg0, arg1, params
        end
      end
  end

=begin
  an important universal SysEx is:
  0xF0  SysEx
  0x7E  Non-Realtime
  0x7F  The SysEx channel. Could be from 0x00 to 0x7F. Here we set it to "disregard channel".
  0x09  Sub-ID -- GM System Enable/Disable
  0xNN  Sub-ID2 -- NN=00 for disable, NN=01 for enable
  0xF7  End of SysEx
=end

# a SystemExclusiveEvent is basicly an 'escape' event, which allows you to send
# arbitraty binary data to a device.  There is hardly any standard for this.
  class SystemExclusiveEvent < MidiEvent

      # value to send to enable GM on a GM compatible device
      # After sending progchanges 0 to 127 have fixed voices, according to the GM specs
      # Bank should probably set to 0 but I think it is ignored
      ENABLE_GM = "\xf0\x7e\x7f\x09\x01\xf7".force_encoding('ascii-8bit')

      # value to send to disable GM on a GM enabled device
      DISABLE_GM = "\xf0\x7e\x7f\x09\x00\xf7".force_encoding('ascii-8bit')

    private
      # new Sequencer, event

      # Parameters:
      # [data] binary blob
      def initialize data, params = nil
        case params when AlsaMidiEvent_i then super(data, params)
        else
          (params ||= {})[:value] = data
          super :sysex, params
        end
      end

    public

      alias :data :value

      def status
        0xf
      end
  end

  SysexEvent = SystemExclusiveEvent

  # a QueueEvent is an event that changes the state of some queue
  # This is an abstract class.
  #
  # QueueEvents must be send to the system_timer port (Sequencer.system_timer)
  # in order to have effect. It is also possible using the API for this.
  class QueueEvent < MidiEvent
    private
      def initialize arg0, arg1 = nil, params = nil
        case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
        else
          (params ||= {})[:queue] = arg1
          super arg0, params
        end
      end
  end

  # Send this event to start a queue. This is not a MIDI event, but an Alsa event.
  class StartEvent < QueueEvent
    private
      # create a new StartEvent
      def initialize queue, params = nil
        case params when AlsaMidiEvent_i then super(queue, params)
        else
          super :start, queue, params
        end
      end
  end

  # request to stop/pause a queue
  class StopEvent < QueueEvent
    private
      def initialize queue, params = nil
        case params when AlsaMidiEvent_i then super(queue, params)
        else
          super :stop, queue, params
        end
      end
  end

  # request to continue with the queue
  class ContinueEvent < QueueEvent
    private
      def initialize queue, params = nil
        case params when AlsaMidiEvent_i then super(queue, params)
        else
          super :continue, queue, params
        end
      end
  end

  # represents a timing event, used for keeping in sync
  class ClockEvent < QueueEvent
    private
      def initialize queue, params = nil
        case params when AlsaMidiEvent_i then super
        else
          super :clock, queue, params
        end
      end
  end

  # specificly a timing event. Each beat (quarter) is divided into 96 ticks (by default at least).
  class TickEvent < QueueEvent
    private
      # new Sequencer, event
      # new queue, [,...]
      def initialize queue, params = nil
        case params when AlsaMidiEvent_i then super
        else
          super :tick, queue, params
        end
      end
  end

  # change the current queue position with this event
  class SetposTickEvent < QueueEvent
    private
=begin
    IMPORTANT: all events must support this way of construction
    arg0 is a Sequencer, arg1 is a LOW LEVEL AlsaMidiEvent_i.
    new sequencer, event
    new queue, tick [, params]
=end
      def initialize arg0, arg1 = nil, params = nil
        case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
        else
          (params ||= {})[:value] = arg1
          super :setpos_tick, arg0, params
        end
      end

    public
      alias :tick :value
  end

  # same as SetposTickEvent, but for realtime queues
  class SetposTimeEvent < QueueEvent
    private
=begin
    IMPORTANT: all events must support this way of construction
    arg0 is a Sequencer, arg1 is a LOW LEVEL AlsaMidiEvent_i.
    new sequencer, event
    new queue, tick [, params]
=end
      def initialize arg0, arg1 = nil, params = nil
        case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
        else
          (params ||= {})[:value] = arg1
          super :setpos_time, arg0, params
        end
      end

      public
      alias :time :value
  end

  # Queue sync event. Don't know what this is
  class SyncPosEvent < QueueEvent
    private
=begin
    IMPORTANT: all events must support this way of construction
    arg0 is a Sequencer, arg1 is a LOW LEVEL AlsaMidiEvent_i.
    new sequencer, event
=end
    # new(queue, value[, params])
      def initialize arg0, arg1 = nil, params = nil
        case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
        else
          (params ||= {})[:value] = arg1
          super :sync_pos, arg0, params
        end
      end

      public
      alias :position :value
  end

   # There is also a META Tempo bit in a MIDI file.

   # TempoEvent. Also abused as a meta event sometimes
  class TempoEvent < QueueEvent
    private
=begin
    IMPORTANT: all events must support this way of construction
    arg0 is a Sequencer, arg1 is a LOW LEVEL AlsaMidiEvent_i.
    new sequencer, event
=end
    # call-seq: new(queue, tempo[, params = nil]) -> TempoEvent
    #
    # Parameters:
    # [queue]     can be a MidiQueue or a queueid.
    # [tempo}     an integer indicating the nr of microseconds per beat
    #             or it can be a Tempo
    #             if +nil+ we use +queue.tempo+ instead
      def initialize queue, tempo = nil, params = nil
        if AlsaMidiEvent_i === tempo
          super(queue, tempo)
        else
          super :tempo, queue, params
          if tempo
            @value = tempo
          else
            require 'rrts/tempo'
            @value = Tempo.new  # NOT queue.tempo
          end
        end
      end

    public
      # the nr of usecs per beat, or the stored Tempo
      alias :tempo :value

      # this is a better name
      def usecs_per_beat
        case @value
        when Tempo then @value.usecs_per_beat
        when AlsaQueueTempo_i then @value.tempo
        else @value
        end
      end

      def to_s
        "TempoEvent[time: #@time] usecs_per_beat: #{usecs_per_beat}"
      end

      # technically it is a meta event
      def status
        0xf
      end
  end

  # To skew the queue obviuously
  class QueueSkewEvent < QueueEvent
    private
=begin
    IMPORTANT: all events must support this way of construction
    arg0 is a Sequencer, arg1 is a LOW LEVEL AlsaMidiEvent_i.
    new sequencer, event
    new queue, skew[, params]
=end
      def initialize arg0, arg1 = nil, params = nil
        case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
        else
          super :queue_skew, arg0, params
          @value = arg1
        end
      end

    public
      alias :skew :value
  end

  # Rather specific request to a machine
  class TuneRequestEvent < MidiEvent
    private
      # new Sequencer, AlsaMidiEvent_i
      # new [,...]
      def initialize arg0 = nil, arg1 = nil
        case arg1 when AlsaMidiEvent_i then super
        else super(:tune_request, arg0)
        end
      end
  end # TuneRequestEvent

  # TODO: these classes can be made on the fly.

  # Request the device to reset itself (if supported)
  class ResetEvent < MidiEvent
    private
      def initialize params = nil, arg1 = nil
        case arg1 when AlsaMidiEvent_i then super
        else super :reset, params
        end
      end
  end # ResetEvent

  # Can be used to check whether a connection is still alive
  class SensingEvent < MidiEvent
    private
      def initialize arg0 = nil, arg1 = nil
        case arg1 when AlsaMidiEvent_i then super
        else super :sensing, arg0
        end
      end
  end # SensingEvent

  # Can be send as a reply, for example to trigger something else
  class EchoEvent < MidiEvent
    private
      def initialize params = nil, arg1 = nil
        case arg1 when AlsaMidiEvent_i then super
        else super :echo, params
        end
      end
  end # EchoEvent

  # THESE ARE STILL BROKEN !!!
  class ClientEvent < MidiEvent
  end

  # Received when a client has joined in
  class ClientStartEvent < ClientEvent
  end

  # Received when a client was removed
  class ClientExitEvent < ClientEvent
  end

  # Received when parameters (but which?) on the client changes.
  class ClientChangeEvent < ClientEvent
  end

  class PortEvent < ClientEvent
  end

  # Received when another client creates a port
  class PortStartEvent < PortEvent
  end

  # Received when another client deletes a port
  class PortExitEvent < PortEvent
  end

  # Received when portparameters change (?)
  class PortChangeEvent < PortEvent
  end

  class SubscriptionEvent < ClientEvent
  end

  # Received when someone subscribes to a port
  class PortSubscribedEvent < SubscriptionEvent
  end

  # Received when someone unsubscribes a port
  class PortUnsubscribedEvent < SubscriptionEvent
  end

  # Free to use, with fixed room
  class UserEvent < MidiEvent
  end

  # What's the difference between Bounce and Echo?
  # Maybe to signal that an event is looping around in the system
  class BounceEvent < MidiEvent
  end

  # Free to use, with variable room
  class VarUserEvent < MidiEvent
  end

  # An event that says things about events
  class MetaEvent < MidiEvent
    private
      # can never be constructed through AlsaMidi since there is no such event
      def initialize params = nil
        super :meta, params
      end

    public

      def priority
        -1
      end

      def status
        0xf
      end
  end

  # This signals that no more events will follow
  class LastEvent < MetaEvent
  end

  # This event can contain descriptional text
  class MetaTextEvent < MetaEvent
    private
      def initialize value, params = nil
        (params ||= {})[:value] = value
        super params
      end
  end

  # see http://www.midi.org/techspecs/rp17.php
  # Can be used for Karaoke
  class LyricsEvent < MetaTextEvent; end

  # free comments
  class CommentEvent < MetaTextEvent; end

  # marker as placed by some program
  class MarkerEvent < MetaTextEvent; end

  # cue point for syncing with movies and clips
  class CuePointEvent < MetaTextEvent; end

  # used to store the name of a voice (like for programchanges)
  class ProgramNameEvent < MetaTextEvent
    private
      def initialize channel, value, params = {}
        params[:channel] = channel
        super(value, params)
      end
  end

  # Voicename would be a better name, but what's the difference?
  class VoiceNameEvent < ProgramNameEvent; end

  # class for time signature changes (like going from 3/4 to 4/4)
  class TimeSignatureEvent < MetaEvent
    private
      # Typically num/denom is 4/4 or 3/4 etc..
      def initialize num, denom, clocks_per_beat = 24, something = nil
        super()
        @num, @denom, @clocks_per_beat = num, denom, clocks_per_beat
        @something = something
      end

    public

      attr :num, :denom, :clocks_per_beat, :something

      # returns a tuple [numerator, denominator]
      def time_signature
        [@num, @denom]
      end
  end # class TimeSignatureEvent

  # signals the use of a specific key, like D sharp, or d minor
  class KeySignatureEvent < MetaEvent
    private
    # key can be :C or :'C#' etc
      def initialize key, major
        super()
        @key, @major = key, major
      end

    public

      attr :key

      def major?
        @major
      end

      # returns a tuple [key, major?]
      def key_signature
        [@key, @major]
      end
  end

  # abstract class. In fact it doesn't really belong here since it uses the
  # RTTS::Node library
  class TrackEvent < MidiEvent
  end

  # Signals the creation of trackdata
  class TrackCreateEvent < TrackEvent
    private
      def initialize
        super(:track_create)
        require_relative 'node/track'
        @value = Node::Track.allocate_key
      end
    public
      alias :key :value
  end

  # for Node internals.
  class ChunkCreateEvent < TrackEvent
    private
      def initialize params = nil
        @split_channels = false
        @combine_notes = @combine_lsb_msb = @combine_progchanges = true
        super(:chunk_create, params)
      end

      #override
      def parse_option k, v
        case k
        when :split_channels then @split_channels = v
        when :combine_lsb_msb then @combine_lsb_msb = v
        when :combine_progchanges then @combine_progchanges = v
        when :combine_notes then @combine_notes = v
        else super
        end
      end

    public

      attr :split_channels, :combine_lsb_msb, :combine_notes, :combine_progchanges
  end

  class TrackPortIndexEvent < TrackEvent
    private
      def initialize i, params = nil
        super(:trackportindex, params)
        @value = i
      end
    public

      alias :portindex :value
  end

  class TrackIntendedDeviceEvent < TrackEvent
    private
      def initialize dev, params = nil
        super(:intended_device, params)
        @value = dev
      end
    public

      alias :intended_device :value
  end

  # if the sequencer gets this event, if will flush.
  class FlushEvent < MetaEvent
  end
end # RRTS