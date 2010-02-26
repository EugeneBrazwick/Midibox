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
    include Driver

    private

    Symbol2Param = { :bank_select=>MIDI_CTL_MSB_BANK, :modwheel=>MIDI_CTL_MSB_MODWHEEL,
                     :modulation_wheel=>MIDI_CTL_MSB_MODWHEEL,
                     :breath_controller=>MIDI_CTL_MSB_BREATH, :breath=>MIDI_CTL_MSB_BREATH,
                     :foot=>MIDI_CTL_MSB_FOOT, :foot_pedal=>MIDI_CTL_MSB_FOOT,
                     :portamento_time=>MIDI_CTL_MSB_PORTAMENTO_TIME,
                     :volume=>MIDI_CTL_MSB_MAIN_VOLUME, :main_volume=>MIDI_CTL_MSB_MAIN_VOLUME,
                     :balance=>MIDI_CTL_MSB_BALANCE,
                     :pan_position=>MIDI_CTL_MSB_PAN, :pan=>MIDI_CTL_MSB_PAN,
                     :expression=>MIDI_CTL_MSB_EXPRESSION,
                     :hold_pedal=>MIDI_CTL_SUSTAIN, :sustain=>MIDI_CTL_SUSTAIN,
                     :hold=>MIDI_CTL_SUSTAIN,
                     :portamento=>MIDI_CTL_PORTAMENTO,
                     :sostenuto=>MIDI_CTL_SOSTENUTO,
                     :soft_pedal=>MIDI_CTL_SOFT_PEDAL,
                     :legato=>MIDI_CTL_LEGATO_FOOTSWITCH, :legato_footswitch=>MIDI_CTL_LEGATO_FOOTSWITCH,
                     :hold2_pedal=>MIDI_CTL_HOLD2, :hold2=>MIDI_CTL_HOLD2,
                     :timbre=>MIDI_CTL_SC2_TIMBRE,
                     :release=>MIDI_CTL_SC3_RELEASE_TIME,
                     :release_time=>MIDI_CTL_SC3_RELEASE_TIME,
                     :attack=>MIDI_CTL_SC4_ATTACK_TIME, :attack_time=>MIDI_CTL_SC4_ATTACK_TIME,
                     :brightness=>MIDI_CTL_SC5_BRIGHTNESS,
                     :reverb=>MIDI_CTL_E1_REVERB_DEPTH,
                     :tremolo=>MIDI_CTL_E2_TREMOLO_DEPTH,
                     :chorus=>MIDI_CTL_E3_CHORUS_DEPTH,
                     :detune=>MIDI_CTL_E4_DETUNE_DEPTH, :celeste=>MIDI_CTL_E4_DETUNE_DEPTH,
                     :phaser=>MIDI_CTL_E5_PHASER_DEPTH,
                     :all_controllers_off=>MIDI_CTL_RESET_CONTROLLERS,
                     :reset_controllers=>MIDI_CTL_RESET_CONTROLLERS,
                     :all_notes_off=>MIDI_CTL_ALL_NOTES_OFF,
                     :all_sounds_off=>MIDI_CTL_ALL_SOUNDS_OFF, :panic=>MIDI_CTL_ALL_SOUNDS_OFF,
                     :omni_off=>MIDI_CTL_OMNI_OFF, :omni_on=>MIDI_CTL_OMNI_ON,
                     :mono=>MIDI_CTL_MONO1,
                     :poly=>MIDI_CTL_MONO2 # ???
                    }
=begin
    IMPORTANT: all events must support this way of construction
    new Sequencer, AlsaMidiEvent_i
    new typesymbol [,...]
=end
    def initialize arg0, arg1 = {}
      case arg1 when AlsaMidiEvent_i
        arg1.populate(arg0, self)
        #       puts "called populate, @type=#@type, type=#{type}"
      else
        @type = arg0
        @flags = { :time_mode_absolute=>true, :time_mode_ticks=>true }  # since this is SND_SEQ_TIME_MODE_ABS which is 0.
        @channel = @velocity = @duration = @value = @param = @source = @dest = @queue = nil
        @off_velocity = @tick = nil
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
            #RTTSError.new("illegal channel #{v}") unless v.between?(0, 15)
            @channel = v
          when :duration then @duration = v
          when :velocity then @velocity = v
          when :off_velocity then @off_velocity = v
          when :source, :sender
            @source = v
          when :dest, :destination then @dest = v
          when :sender_queue
            @sender_queue = v # LEAVE THE HACKING to alsa_midi_event yes please... .respond_to(:id) ? v.id : v
          when :tick
            @tick = v
#             puts "#{File.basename(__FILE__)}:#{__LINE__}:@tick:=#{v}"
          when :queue_id
            @queue_id = v
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
      return (Symbol === @param ? Symbol2Param[@param] : @param), @flags[:coarse]
    end

    Flag2IntMap = {
                    :time_mode_real=>SND_SEQ_TIME_STAMP_REAL,
                    :time_mode_ticks=>SND_SEQ_TIME_STAMP_TICK,
                    :time_mode_tick=>SND_SEQ_TIME_STAMP_TICK,
                    :time_mode_relative=>SND_SEQ_TIME_MODE_REL,
                    :time_mode_absolute=>SND_SEQ_TIME_MODE_ABS,
                    :time_real=>SND_SEQ_TIME_STAMP_REAL,
                    :time_ticks=>SND_SEQ_TIME_STAMP_TICK,
                    :time_tick=>SND_SEQ_TIME_STAMP_TICK,
                    :time_relative=>SND_SEQ_TIME_MODE_REL,
                    :time_absolute=>SND_SEQ_TIME_MODE_ABS
                  }
    Type2IntMap = { :noteon=>SND_SEQ_EVENT_NOTEON,
                    :noteoff=>SND_SEQ_EVENT_NOTEOFF,
                    :note=>SND_SEQ_EVENT_NOTE,
                    :keypress=>SND_SEQ_EVENT_KEYPRESS,
                    :controller=>SND_SEQ_EVENT_CONTROLLER,
                    :control14=>SND_SEQ_EVENT_CONTROL14,
                    :pgmchange=>SND_SEQ_EVENT_PGMCHANGE,
                    :pitchbend=>SND_SEQ_EVENT_PITCHBEND,
                    :chanpress=>SND_SEQ_EVENT_CHANPRESS,
                    :songpos=>SND_SEQ_EVENT_SONGPOS,
                    :songsel=>SND_SEQ_EVENT_SONGSEL,
                    :sysex=>SND_SEQ_EVENT_SYSEX,
                    :start=>SND_SEQ_EVENT_START,
                    :stop=>SND_SEQ_EVENT_STOP,
                    :continue=>SND_SEQ_EVENT_CONTINUE,
                    :clock=>SND_SEQ_EVENT_CLOCK,
                    :tick=>SND_SEQ_EVENT_TICK,
                    :setpos_tick=>SND_SEQ_EVENT_SETPOS_TICK,
                    :setpos_time=>SND_SEQ_EVENT_SETPOS_TIME,
                    :syncpos=>SND_SEQ_EVENT_SYNC_POS,
                    :sync_pos=>SND_SEQ_EVENT_SYNC_POS,
                    :tempo=>SND_SEQ_EVENT_TEMPO,
                    :queue_skew=>SND_SEQ_EVENT_QUEUE_SKEW,
                    :skew=>SND_SEQ_EVENT_QUEUE_SKEW,
                    :tune_request=>SND_SEQ_EVENT_TUNE_REQUEST,
                    :reset=>SND_SEQ_EVENT_RESET,
                    :sensing=>SND_SEQ_EVENT_SENSING,
                    :echo=>SND_SEQ_EVENT_ECHO
                    }
    # returns [type, flags] as two integers from the current @type and @flags
    def debunktypeflags_i
      flags = 0
      for k, v in @flags
        v and f = Flag2IntMap[k] and flags |= f
      end
      type = Type2IntMap[@type] or RRTSError.new("internal error: no mapping for :#{@type}")
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
    attr :time
    # this should be kept simple. These are MidiPorts
    attr_accessor :source, :dest
    # receiver queue.
    attr :receiver_queue_id
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
    attr :value
    # queue_id: the queueid (at this point) of a queue control message
    attr :queue_id
    # these are MidiPorts for connection events
    attr :connnect_sender, :connect_dest

    def schedule_tick
      not_implemented
    end

    def schedule_real
      not_implemented
    end

    # set_noteon  MUST BE CONSTRUCTORS!
    # set_noteoff
    # set pgmchange/pitchbend/chanpress/note/on/off/keypress/controller

    # set_subs

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
    def initialize arg0, arg1 = nil, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        super :noteoff, arg0, arg1, params
      end
    end

  end

  class NoteEvent < VoiceEvent
    private
    def initialize arg0, arg1 = nil, velocity = nil, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        params[:velocity] = velocity
        super :note, arg0, arg1, params
      end
    end
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

    In addition the option 'coarse:true' can be given to actually only send to coarse
    value where we use value<<7 as effictive value
    It is also possible to pass a tuple as 'value'. 
    ControllerEvent.new channel, :bank_select, [1, 23]
    This would select bank 1*128+23.
=end
    def initialize arg0, arg1 = nil, value = 0, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        params, value = value, 0 if Hash === value
        params[:param] = arg1
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

  class StartEvent < MidiEvent
    private
    # new Sequencer, event
    # new queue, [,...]
    def initialize arg0, arg1 = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        super :start, arg0, params
      end
    end
  end

  class StopEvent < MidiEvent
    private
    # new Sequencer, event
    # new queue, [,...]
    def initialize arg0, arg1 = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        super :stop, arg0, params
      end
    end
  end

  class ContinueEvent < MidiEvent
    private
    # new Sequencer, event
    # new queue, [,...]
    def initialize arg0, arg1 = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        super :continue, arg0, params
      end
    end
  end

  class QueueEvent < MidiEvent
    private
    # new Sequencer, event
    # new type, queue, [,...]
    def initialize arg0, arg1 = nil, params = {}
      case arg1 when AlsaMidiEvent_i then super(arg0, arg1)
      else
        params[:queue_id] = arg1
        super type, params
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
