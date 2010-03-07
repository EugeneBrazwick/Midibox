#!/usr/bin/ruby1.9.1 -w

require_relative 'alsa_midi.so'
require 'forwardable'

module RRTS

=begin

To make sure we are as fast as possible we instantiate all properties as
ivars. So no forwarding.
All possible properties are supported but will be nil.
At least, today...

To create an event use Sequencer.input_event
=end
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
      :regist_parm_num=>MIDI_CTL_REGIST_PARM_NUM_MSB,
      :nonreg_parm_num_lsb=>MIDI_CTL_NONREG_PARM_NUM_LSB,
      :regist_parm_num_lsb=>MIDI_CTL_REGIST_PARM_NUM_LSB
      }
=begin
    IMPORTANT: all events must support this way of construction
    new Sequencer, AlsaMidiEvent_i
    new typesymbol [,...]
=end
    def initialize arg0, arg1 = {}
      case arg1 when AlsaMidiEvent_i # input_event handling
        arg1.populate(arg0, self) # See alsa_midi++.cpp
        #       puts "called populate, @type=#@type, type=#{type}"
      else # result of user construction
        @type = arg0 or raise RRTSError.new("illegal type man!!")
        # Don't use flags, as it seems rather costly using a hash here.
        @flags = { :time_mode_absolute=>true, :time_mode_ticks=>true }  # since this is SND_SEQ_TIME_MODE_ABS which is 0.
        @channel = @velocity = @value = @param = @source = nil
        # @dest = @queue = nil  used???
        # @off_velocity = @duration = hardly ever used
        @time = nil
#         puts "#{File.basename(__FILE__)}:#{__LINE__}:@tick:=nil"
        for k, v in arg1
          case k
          when :value
            if arg1[:param]
              case v
              when TrueClass, FalseClass then @value = v ? 64 : 0
              else @value = v
              end
              @value <<= 7 if arg1[:coarse]
            else
              @value = v
            end
          when :channel
            #RTTSError.new("illegal channel #{v}") unless v.between?(1, 16)
             # can be a range or maybe even an array of channels!!
            # or an array of ranges...
            @channel = v
#             puts "#{File.basename(__FILE__)}:#{__LINE__}:channel:=#@channel"
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
          when :time_mode_tick then @flags[:time_mode_tick] = v; @flags[:time_mode_real] = !v
          when :time_mode_real then @flags[:time_mode_tick] = !v; @flags[:time_mode_real] = v
          when :time_mode_relative
            @flags[:time_mode_relative] = v
            @flags[:time_mode_absolute] = !v
          when :time_mode_absolute
            @flags[:time_mode_relative] = !v
            @flags[:time_mode_absolute] = v
          when :coarse
            if v && arg1[:value] > 0x7f
              raise RRTSError.new("overflowing coarse controller value[#{arg1[:param]}] #{arg1[:value]}")
            end
            @flags[:coarse] = v
          when :param then @param = v
          else raise RRTSError.new("illegal option '#{k}' for #{self.class}")
          end
        end
      end
    end

    # returns tuple [param_id, coarse_b]
    # coarse_b should be true if we need to send a single event.
    # otherwise an MSB + LSB should both be send
    def debunkparam_i
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
                    :control14=>SND_SEQ_EVENT_CONTROL14,
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
                    :echo=>SND_SEQ_EVENT_ECHO #50
                    }
    # returns [type, flags] as two integers from the current @type and @flags
    def debunktypeflags_i
#       puts "#{File.basename(__FILE__)}:#{__LINE__}:debunktypeflags_i"
      flags = 0
      for k, v in @flags
        v and f = Flag2IntMap[k] and flags |= f
      end
      type = Type2IntMap[@type] or raise RRTSError.new("internal error: no mapping for :#{@type}")
#       puts "returning [#{type}, #{flags}], type=#@type"
      return type, flags
    end

    public

#     attr :abstime?, :reltime?, :direct?, :reserved?, :prior?, :fixed?, :variable?, :tick?, :real?
#     attr :result_type?, :note_type?, :control_type?, :channel_type?, :message_type?,
#          :subscribe_type?, :sample_type?, :user_type?, :instr_type?, :fixed_type?,
#          :variable_type?, :varusr_type?

#     def type_check?
#       not_implemented
#     end

    # the typeid, a symbol equal to the suffix of the event name in lower case
    # Examples: :start, :sensing, :pgmchange, :noteon
    attr :type
    # timestamp of event, either in ticks (int) or realtime [secs, nanosecs]
    attr_accessor :time
    alias :tick :time
    alias :tick= :time=
    # this should be kept simple. These are MidiPorts
    attr_accessor :source, :dest
    alias :sender :source
    alias :sender= :source=

    # hash of bools.
    attr_accessor :flags, :sender_queue
    # receiver queue. id or MidiQueue
    attr :receiver_queue
    # notes and control events have a channel. We use the range 1..16
    # The channel can be set to an enumerable. This will make the
    # messages be sent to all the given channels
    attr :channel
    # notes have these:
    attr :velocity, :off_velocity, :duration
    # can be 'event' for result messages, normally used for controls
    attr :param
    # value is a note or a control-value, a result-value, or a queue-value, also a sysex binary string
    # normally integer
    # Can be ticks for queues, time for queues, or a [skew, skew_base] tuple
    # Can be a MidiPort for port message, and a MidiClient for client messages
    # It is legal to pass notenames as strings like 'C#5' or 'Bb3'. [A-Ga-g](#|b)?[0-9]
    # When retrieved they will be integers though.
    attr_accessor :value
    # queue: the queue (id or MidiQueue) of a queue control message
    attr_accessor :queue
    # these are MidiPorts for connection events
    attr :connnect_sender, :connect_dest

    def schedule_tick
      not_implemented
    end

    def schedule_real
      not_implemented
    end

    def <=> other
      case @time
      when Array
        d = @time[0] - other.time[0]
        d != 0 ? d : @time[1] - other.time[1]
      else
        @time - other.time
      end
    end

  end  # MidiEvent

=begin  queue events ?
  class ClockEvent < MidiEvent
    private
    def initialize arg0, params = {}
      case params when AlsaMidiEvent_i then super
      else super :clock, params
      end
    end
  end

  class TickEvent < MidiEvent
    private
    def initialize arg0, params = {}
      case params when AlsaMidiEvent_i then super
      else super :tick, params
      end
    end
  end
=end

  # a VoiceEvent has a channel (arg0), and also a value (arg1) (could be 'note')
  class VoiceEvent < MidiEvent
    private
    # new Sequencer, event
    # new type, channel, value, [,...]
    def initialize arg0, arg1 = nil, value = nil, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        params[:channel] = arg1
        params[:value] = value
        super arg0, params
      end
    end
  end

  class NoteOnEvent < VoiceEvent

    private
    # new sequencer, event
    # new channel, note, velocity [,...]
    # It is allowed to use strings like 'C4' or 'd5' or 'Eb6' for 'note' (arg1)
    def initialize arg0, arg1 = nil, velocity = nil, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        params[:velocity] = velocity
        super :noteon, arg0, arg1, params
      end
    end

    public

    alias :note :value
  end

  class KeypressEvent < VoiceEvent  # aka 'aftertouch'
    private
    # new sequencer, event
    # new channel, note, pressure[,...]
    # It is allowed to use strings like 'C4' or 'd5' or 'Eb6' for 'note' (arg1)
    def initialize arg0, arg1 = nil, velocity = nil, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        params[:velocity] = velocity
        super :keypress, arg0, arg1, params
      end
    end

  public

    alias :note :value
    alias :pressure :velocity
  end

  class NoteOffEvent < VoiceEvent
    private
    # new sequencer, event
    # new channel, note [,...]
    # It is allowed to use strings like 'C4' or 'd5' or 'Eb6' for 'note' (arg1)
    def initialize arg0, arg1 = nil, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        super :noteoff, arg0, arg1, params
      end
    end

    public
    alias :note :value
  end

  class NoteEvent < VoiceEvent
    private
    # NoteEvent.new channel, note, velocity [, ...]
    # It is allowed to use strings like 'C4' or 'd5' or 'Eb6' for 'note' (arg1)
    def initialize arg0, arg1 = nil, velocity = nil, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        params[:velocity] = velocity
        super :note, arg0, arg1, params
      end
    end
    public
    alias :note :value
  end

  class ControllerEvent < VoiceEvent
    private
    # IMPORTANT: if you use a controller-parameter that requires an on/off value
    # then 0 is off and 64 is on. You can use the constants below as well.
    # Or you pass 'false' or 'true' for value.
    ON = 0x40
    OFF = 0x0
=begin
    IMPORTANT: all events must support this way of construction
    arg0 is a Sequencer, arg1 is a LOW LEVEL AlsaMidiEvent_i.
    new sequencer, event
    new channel, param, value [, params ]
    new channel, param [, params ]

    'param' can be a symbol from:

   IMPORTANT: the value you pass here must be a 14 bits int, or else 2 7 bit ints.
   Two events will actually be sent (always).
   Pass coarse: false to use the value as a single 7 bits int, while passing 0 as lsb.
   Even in this case two events are sent.
    :bank_select (14 bits), or better 7+7
    :modulation_wheel (14)
    :breath_controller (14)
    :foot_pedal (14)
    :portamento_time (14)
    :data_entry (14)
    :volume (14)
    :balance (14)
    :pan_position(14)
    :expression(14)

    :hold_pedal (1), portamento (1), sustenuto(10, soft(1), legato(1)
    :hold_2_pedal (1).  Note that value 64 (bit 7) is used for this.
    IMPORTANT: passing '1' here does therefore not activate the control!

    These are 7 bits:
    :timbre, :release, :attack, :brightness,
    :effects_level, :tremulo_level/:tremulo, :chorus_level/:chorus,
    :celest_level/:celeste/:detune
    :phaser

    These are 0 bits:
    :all_controllers_off (single channel)
    :all_notes_off (nonlocal, except pedal)
    :all_sound_off/:panic (nonlocal)
    :omni_off, :omni_on, :mono, :poly

    It is also possible to pass a tuple as 'value'.
    ControllerEvent.new channel, :bank_select, [1, 23]
    This would select bank 1*128+23.
=end
    def initialize arg0, arg1 = nil, value = 0, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        params, value = value, 0 if Hash === value
        params[:param] = Driver::param2sym(arg1)
        super :controller, arg0, value, params
      end
    end

    public
    alias :program :value
  end

  class Control14Event < VoiceEvent
    private
=begin
    IMPORTANT: all events must support this way of construction
    arg0 is a Sequencer, arg1 is a LOW LEVEL AlsaMidiEvent_i.
    new sequencer, event
    new channel, param, value, params
=end
    def initialize arg0, arg1 = nil, value = nil, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        params[:param] = arg1
        super :control14, arg0, value, params
      end
    end
  end

  class ProgramChangeEvent < VoiceEvent
    private
=begin
    IMPORTANT: all events must support this way of construction
    arg0 is a Sequencer, arg1 is a LOW LEVEL AlsaMidiEvent_i.
    new sequencer, event
    new channel, program [, params ]
    new channel, [bank_msb, program] [, params]
    new channel , [bank_msb, bank_lsb, program] ...
=end
    def initialize arg0, arg1 = nil, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        super :pgmchange, arg0, arg1, params
      end
    end

    public
    alias :program :value
  end

  class PitchbendEvent < VoiceEvent
    private
=begin
    new sequencer, event
    new channel, value [, params ]
    Note that value is a 14 bits signed integer
    in the range -0x2000 to 0x2000
=end
    def initialize arg0, arg1 = nil, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        super :pitchbend, arg0, arg1, params
      end
    end
  end

  class ChannelPressureEvent < VoiceEvent
    private
    # new Sequencer, event
    # new channel, pressure [,...]
    def initialize arg0, arg1 = nil, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        super :chanpress, arg0, arg1, params
      end
    end
  end

  # has a channel ????  FIXME ??
  class SongPositionEvent < VoiceEvent
    private
    def initialize arg0, arg1 = nil, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        super :songpos, arg0, arg1, params
      end
    end
  end

  # has a channel ????  FIXME ??
  class SongSelectionEvent < VoiceEvent
    private
    def initialize arg0, arg1 = nil, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        super :songsel, arg0, arg1, params
      end
    end
  end

  class SystemExclusiveEvent < MidiEvent
    private
    # new Sequencer, event
    # new data [,...].  NOTE: see low level API, where does the memory stay??????
    def initialize arg0, arg1 = nil, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        params[:value] = arg0
        super :sysex, params
      end
    end

    public

    alias :data :value
  end

  SysexEvent = SystemExclusiveEvent

  class QueueEvent < MidiEvent
    private
    # new Sequencer, event
    # new type, queue, [,...]
    def initialize arg0, arg1 = nil, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        params[:queue] = arg1
        super arg0, params
      end
    end
  end

  class StartEvent < QueueEvent
    private
    # new Sequencer, event
    # new queue, [,...]
    def initialize arg0, arg1 = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        super :start, arg0, arg1
      end
    end
  end

  class StopEvent < QueueEvent
    private
    # new Sequencer, event
    # new queue, [,...]
    def initialize arg0, arg1 = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        super :stop, arg0, arg1
      end
    end
  end

  class ContinueEvent < QueueEvent
    private
    # new Sequencer, event
    # new queue, [,...]
    def initialize arg0, arg1 = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        super :continue, arg0, arg1
      end
    end
  end

  class ClockEvent < QueueEvent
    private
    # new Sequencer, event
    # new queue, [,...]
    def initialize arg0, arg1 = {}
      case arg1 when AlsaMidiEvent_i then super
      else
        super :clock, arg0, params
      end
    end
  end

  class TickEvent < QueueEvent
    private
    # new Sequencer, event
    # new queue, [,...]
    def initialize arg0, arg1 = {}
      case arg1 when AlsaMidiEvent_i then super
      else
        super :tick, arg0, params
      end
    end
  end

  class SetposTickEvent < QueueEvent
    private
=begin
    IMPORTANT: all events must support this way of construction
    arg0 is a Sequencer, arg1 is a LOW LEVEL AlsaMidiEvent_i.
    new sequencer, event
    new queue, tick [, params]
=end
    def initialize arg0, arg1 = nil, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        params[:value] = arg1
        super :setpos_tick, arg0, params
      end
    end

    public
    alias :tick :value
  end

  class SetposTimeEvent < QueueEvent
    private
=begin
    IMPORTANT: all events must support this way of construction
    arg0 is a Sequencer, arg1 is a LOW LEVEL AlsaMidiEvent_i.
    new sequencer, event
    new queue, tick [, params]
=end
    def initialize arg0, arg1 = nil, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        params[:value] = arg1
        super :setpos_time, arg0, params
      end
    end

    public
    alias :time :value
  end

  class SyncPosEvent < QueueEvent
    private
=begin
    IMPORTANT: all events must support this way of construction
    arg0 is a Sequencer, arg1 is a LOW LEVEL AlsaMidiEvent_i.
    new sequencer, event
    new queue, value[, params]
=end
    def initialize arg0, arg1 = nil, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        params[:value] = arg1
        super :sync_pos, arg0, params
      end
    end

    public
    alias :position :value
  end

   # There is also a META Tempo bit in a MIDI file.
  class TempoEvent < QueueEvent
    private
=begin
    IMPORTANT: all events must support this way of construction
    arg0 is a Sequencer, arg1 is a LOW LEVEL AlsaMidiEvent_i.
    new sequencer, event
    new queue, tempo[, params]
=end
    def initialize arg0, arg1 = nil, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        params[:value] = arg1
        super :tempo, arg0, params
      end
    end

    public
    alias :tempo :value
  end

  class QueueSkewEvent < QueueEvent
    private
=begin
    IMPORTANT: all events must support this way of construction
    arg0 is a Sequencer, arg1 is a LOW LEVEL AlsaMidiEvent_i.
    new sequencer, event
    new queue, skew[, params]
=end
    def initialize arg0, arg1 = nil, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        params[:value] = arg1
        super :queue_skew, arg0, params
      end
    end

    public
    alias :skew :value
  end

  class TuneRequestEvent < MidiEvent
    private
    # new Sequencer, AlsaMidiEvent_i
    # new [,...]
    def initialize arg0 = {}, arg1 = nil
      case arg1 when AlsaMidiEvent_i then super
      else super(:tune_request, arg0)
      end
    end
  end # TuneRequestEvent

  # TODO: these classes can be made on the fly.
  class ResetEvent < MidiEvent
    private
    def initialize arg0 = {}, arg1 = nil
      case arg1 when AlsaMidiEvent_i then super
      else super :reset, arg0
      end
    end
  end # ResetEvent

  class SensingEvent < MidiEvent
    private
    def initialize arg0 = {}, arg1 = nil
      case arg1 when AlsaMidiEvent_i then super
      else super :sensing, arg0
      end
    end
  end # SensingEvent

  class EchoEvent < MidiEvent
    private
    def initialize arg0 = {}, arg1 = nil
      case arg1 when AlsaMidiEvent_i then super
      else super :echo, arg0
      end
    end
  end # EchoEvent

  class ClientEvent < MidiEvent
  end

  class ClientStartEvent < ClientEvent
  end

  class ClientExitEvent < ClientEvent
  end

  class ClientChangeEvent < ClientEvent
  end

  class PortEvent < ClientEvent
  end

  class PortStartEvent < PortEvent
  end

  class PortExitEvent < PortEvent
  end

  class PortChangeEvent < PortEvent
  end

  class SubscriptionEvent < ClientEvent
  end

  class PortSubscribedEvent < SubscriptionEvent
  end

  class PortUnsubscribedEvent < SubscriptionEvent
  end

  class UserEvent < MidiEvent
  end

  class BounceEvent < MidiEvent
  end

  class VarUserEvent < MidiEvent
  end
end # RRTS
