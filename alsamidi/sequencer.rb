
require_relative 'rrts'
require_relative 'midievent'
require 'forwardable'

module RRTS

  # This class is the main client for the Alsa MIDI system.
  # It is possible to use more than one Sequencer within an application
  # Delegates to:
  # *  AlsaSequencer_i#poll_descriptors
  # *  AlsaSequencer_i#poll_descriptors_count
  # *  AlsaSequencer_i#poll_descriptors_revents
  # *  AlsaSequencer_i#drain_output,  with alias +flush+
  # *  AlsaSequencer_i#start_queue
  # *  AlsaSequencer_i#nonblock
  # *  AlsaSequencer_i#alloc_named_queue,  but please use MidiQueue#new
  # *  AlsaSequencer_i#set_queue_tempo
  # *  AlsaSequencer_i#output_buffer_size
  # *  AlsaSequencer_i#output_buffer_size=
  # *  AlsaSequencer_i#input_buffer_size
  # *  AlsaSequencer_i#input_buffer_size=
  # *  AlsaSequencer_i#sync_output_queue
  # *  AlsaSequencer_i#create_port, please use MidiPort.new
  # *  AlsaSequencer_i#event_output
  # *  AlsaSequencer_i#event_output_buffer
  # *  AlsaSequencer_i#event_output_direct
  # *  AlsaSequencer_i#queue_status
  # *  AlsaSequencer_i#client_name
  # *  AlsaSequencer_i#remove_events
  # *  AlsaSequencer_i#client_pool
  # *  AlsaSequencer_i#client_pool=
  # *  AlsaSequencer_i#client_pool_output=
  # *  AlsaSequencer_i#client_pool_output_room=
  # *  AlsaSequencer_i#client_pool_input=
  # *  AlsaSequencer_i#reset_pool_input
  # *  AlsaSequencer_i#reset_pool_output
  # *  AlsaSequencer_i#system_infp
  # *  AlsaSequencer_i#dump_notes=
  # *  AlsaClientInfo_i#broadcast_filter?
  # *  AlsaClientInfo_i#error_bounce?
  # *  AlsaClientInfo_i#event_lost
  # *  AlsaClientInfo_i#events_lost
  # *  AlsaClientInfo_i#num_ports
  # *  AlsaClientInfo_i#num_open_ports
  # *  AlsaClientInfo_i#type
class Sequencer
include Driver # open up namespace
extend Forwardable
  # for #new
  Duplex = SND_SEQ_OPEN_DUPLEX
  # for #new
  InputOnly = SND_SEQ_OPEN_INPUT
  # for #new
  OutputOnly = SND_SEQ_OPEN_OUTPUT
  # for #new
  Blocking = false
  # for #new
  NonBlocking = true
  # for the poll methods
  PollIn = POLLIN
  # for the poll methods
  PollOut = POLLOUT
private
#   parameters:
#     [client_name] name of the instantiated client, if nil no client will be instantiated
#     [params]     hash of optional parameters:
#        [:name]         default 'default'
#        [:openmode]     default Duplex
#        [:map_ports]    default true if clientname yields true
#        [:blockingmode] default Blocking
#        [:dump_notes]   if true dump to stderr and do NOT play them!! Only works with HACKED cpp
#                        backend
#     [block] encapsulation for automatic close. Works like IO::open.
  def initialize client_name = nil, params = nil, &block
    @client = @handle = nil
    @client_id = @ports = @ports_index = @clients = nil  # not guaranteed open does this
    open client_name, params, &block
  end

  def initialize_copy other
    @handle = other.copy_to_i
  end

protected

  def copy_to_i handle
    @handle.copy_to handle
  end

public


# See #new
# Only call this after a close, if you want to reopen it.
# Just use 'new'.
  def open client_name = nil, params = nil
    close
    name = 'default'
    openmode, blockingmode = Duplex, Blocking
    map_ports = client_name
    dump_notes = false
    if params
      for key, value in params
        case key
        when :name then name = value
        when :openmode then openmode = value
        when :blockingmode then blockingmode = value
        when :clientname then clientname = value
        when :map_ports then map_ports = value
        when :dump_notes then dump_notes = true
        else
          raise RRTSError.new("Illegal parameter '#{key}' for Sequencer")
        end
      end
    end
    @handle = seq_open name, openmode, blockingmode
    begin
      @handle.dump_notes = true if dump_notes
      @handle.client_name = client_name if client_name
      @client_id = @handle.client_id
      ports! if map_ports
      @client = clients[@client_id]  # ports! is not necessarily called!
      if block_given?
        begin
          yield self
        ensure
          puts "#{File.basename(__FILE__)}:#{__LINE__}:ensure close"
          close
        end
      end
    rescue
      close
      raise
    end
  end

  # closes the sequencer. Must be called to free resources, unless a block is passed to 'new'
  def close
    return unless @handle
    t = @handle
    @handle = nil
    t.close
    @client = @client_id = @ports = @ports_index = @clients = nil
  end

  # us. a MidiClient
  attr :client
  # us, an integer client_id. Same as client.client
  attr :client_id

  # client_name = newname
  def client_name= arg
    @client.name = @handle.client_name = arg
  end

  Klassmap = { SND_SEQ_EVENT_CLOCK=>ClockEvent, SND_SEQ_EVENT_NOTE=>NoteEvent,
               SND_SEQ_EVENT_KEYPRESS=>NoteEvent,
               SND_SEQ_EVENT_NOTEON=>NoteOnEvent, SND_SEQ_EVENT_NOTEOFF=>NoteOffEvent,
               SND_SEQ_EVENT_CONTROLLER=>ControllerEvent,
               SND_SEQ_EVENT_PGMCHANGE=>ProgramChangeEvent,
               SND_SEQ_EVENT_PITCHBEND =>PitchbendEvent,
               SND_SEQ_EVENT_CHANPRESS=>ChannelPressureEvent,
               SND_SEQ_EVENT_CONTROL14=>Control14Event,
               SND_SEQ_EVENT_SYSEX=>SystemExclusiveEvent,
               SND_SEQ_EVENT_SONGPOS=>SongPositionEvent,
               SND_SEQ_EVENT_SONGSEL=>SongSelectionEvent,
               SND_SEQ_EVENT_START=>StartEvent,
               SND_SEQ_EVENT_STOP=>StopEvent,
               SND_SEQ_EVENT_CONTINUE=>ContinueEvent,
               SND_SEQ_EVENT_TICK=>TickEvent,
               SND_SEQ_EVENT_SETPOS_TICK=>SetposTickEvent,
               SND_SEQ_EVENT_SETPOS_TIME=>SetposTimeEvent,
               SND_SEQ_EVENT_SYNC_POS=>SyncPosEvent,
               SND_SEQ_EVENT_TEMPO=>TempoEvent,
               SND_SEQ_EVENT_QUEUE_SKEW=>QueueSkewEvent,
               SND_SEQ_EVENT_TUNE_REQUEST=>TuneRequestEvent,
               SND_SEQ_EVENT_RESET=>ResetEvent,
               SND_SEQ_EVENT_SENSING=>SensingEvent,
               SND_SEQ_EVENT_ECHO=>EchoEvent,
               SND_SEQ_EVENT_CLIENT_START=>ClientStartEvent,
               SND_SEQ_EVENT_CLIENT_EXIT=>ClientExitEvent,
               SND_SEQ_EVENT_CLIENT_CHANGE=>ClientChangeEvent,
               SND_SEQ_EVENT_PORT_START=>PortStartEvent,
               SND_SEQ_EVENT_PORT_EXIT=>PortExitEvent,
               SND_SEQ_EVENT_PORT_CHANGE=>PortChangeEvent,
               SND_SEQ_EVENT_PORT_SUBSCRIBED=>PortSubscribedEvent,
               SND_SEQ_EVENT_PORT_UNSUBSCRIBED=>PortUnsubscribedEvent,
               SND_SEQ_EVENT_USR0=>UserEvent,
               SND_SEQ_EVENT_USR1=>UserEvent,
               SND_SEQ_EVENT_USR2=>UserEvent,
               SND_SEQ_EVENT_USR3=>UserEvent,
               SND_SEQ_EVENT_USR4=>UserEvent,
               SND_SEQ_EVENT_USR5=>UserEvent,
               SND_SEQ_EVENT_USR6=>UserEvent,
               SND_SEQ_EVENT_USR7=>UserEvent,
               SND_SEQ_EVENT_USR8=>UserEvent,
               SND_SEQ_EVENT_USR9=>UserEvent,
               SND_SEQ_EVENT_BOUNCE=>BounceEvent,
               SND_SEQ_EVENT_USR_VAR0=>VarUserEvent,
               SND_SEQ_EVENT_USR_VAR1=>VarUserEvent,
               SND_SEQ_EVENT_USR_VAR2=>VarUserEvent,
               SND_SEQ_EVENT_USR_VAR3=>VarUserEvent,
               SND_SEQ_EVENT_USR_VAR4=>VarUserEvent
             }

# Returns a tuple event + boolean, or nil
#
#   Obtains a MidiEvent from sequencer.
#   This function firstly receives the event byte-stream data from sequencer as much as possible at once.
#   Then it retrieves the first event record.
#   By calling this function sequentially, events are extracted from the input buffer.
#   If there is no input from sequencer, function falls into sleep in blocking mode until an event is received,
#   or returns nil in non-blocking mode. Occasionally, it may raise ENOSPC error. This means that the input
#   FIFO of sequencer overran, and some events are lost. Once this error is returned, the input FIFO is cleared automatically.
#
#   Function returns the event plus a boolean indicating more bytes remain in the input buffer
#   Application can determine from the returned value whether to call input once more or not,
#       if there's more data it will probably(!) not block, even in blocking mode.
#
  def event_input
    (ev, more = @handle.event_input) or return nil
#     typeid = ev.typeid
    klass = Klassmap[ev.type] || MidiEvent
    #     puts "#{File.basename(__FILE__)}:#{__LINE__}:typeid=#{typeid},vel=#{ev_i.velocity},NOTEON=#{SND_SEQ_EVENT_NOTEON}"
# LET's fix things later.
#    if typeid == SND_SEQ_EVENT_NOTEON && ev.velocity == 0
#       klass, typeid = NoteOffEvent, SND_SEQ_EVENT_NOTEOFF
#     end
=begin
     we should prevent the situation that we must call 24 if_type and get_attrib methods.
     So our class must be populated by the C++ library
     What is required is based solely on the typeid
=end
#     puts "Instantiating #{klass}, since ev.type=#{ev.type.inspect}"
    return klass.new(self, ev), more
  end

  def_delegators :@handle, :poll_descriptors, :poll_descriptors_count, :poll_descriptors_revents,
                 :drain_output, :start_queue, :nonblock,
                 # do not use alloc_named_queue, but say 'MidiQueue.new'
                 :alloc_named_queue,
                 :set_queue_tempo,
                 :output_buffer_size=, :output_buffer_size,
                 :input_buffer_size=, :input_buffer_size, :sync_output_queue,
                 :create_port, :event_output, :queue_status,
                 :event_output_buffer, :event_output_direct, :client_name,
                 :remove_events, :client_pool, :client_pool=, :client_pool_output=,
                 :client_pool_output_room=, :client_pool_input=, :reset_pool_output,
                 :reset_pool_input, :system_info, :dump_notes=

  # the following two are here for completeness sake. Please use the MidiPort methods instead!
  def_delegators :@handle, :connect_from, :connect_to

  # drain_output is just a flush, so let's support that name:
  def_delegator :@handle, :drain_output, :flush

  # this means a sequencer behaves a lot like a client
  #def_delegator :@client, :client_name, :name  CONFLICTS with 'name == default'... COnfusing
  def_delegators :@client, :broadcast_filter?, :error_bounce?, :event_lost, :events_lost,
                           :num_ports, :num_open_ports, :type

  # self << MidiEvent
  def << event
#     puts "#{File.basename(__FILE__)}:#{__LINE__}: << event(#{event.inspect})"
    @handle.event_output event
    self
  end

  # MidiPort parse_address pattern. In addition to '0:0' or 'UM-2:1' we also understand 'UM-2 PORT2'
  # May throw AlsaMidiError if the port is invalid or does not exist
  def parse_address portspec
#     puts "#{File.basename(__FILE__)}:#{__LINE__}:parse_address(#{portspec.inspect}),ports=#{ports.keys.inspect}"
    midiport = ports[portspec] and return midiport
#     puts "#{File.basename(__FILE__)}:#{__LINE__}:parse_address(#{portspec.inspect})"
    port(@handle.parse_address(portspec))
  end

  # MidiPort port clientid, portid
  # MidiPort port portspecstring
  # MidiPort port clientstring, portid
  # MidiPort port :specialportsymbol ,  supported are :system_timer and :subscribers_unknown
  # MidiPort port [clientid, portid]
  # The port must exist
  def port clientid, portid = nil
    case clientid
    when Array then return port(clientid[0], clientid[1])
    when String
      return parse_address(clientid) unless portid
    when :subscribers_unknown then return subscribers_unknown
    when :system_timer then return system_timer
    end
    t = @ports_index && @ports_index[clientid]
    unless t && t[portid]
      ports!
      t = @ports_index[clientid]
      unless t && t[portid]
        raise AlsaMidiError.new("Internal error, port #{clientid}:#{portid} not located\n" +
                                "ports = #{ports.map{|k,v| v.full_name}.inspect}")
      end
    end
    t[portid]
  end

  @@subscribers_unknown_port = nil
  @@system_timer_port = nil

  # The special port 254:253
  def subscribers_unknown_port
    @@subscribers_unknown_port ||= MidiPort.new(self, 'SUBSCRIBERS UNKNOWN',
                                                client_id: SND_SEQ_ADDRESS_SUBSCRIBERS,
                                                port: SND_SEQ_ADDRESS_UNKNOWN)
  end

  # The special port 0:0
  def system_timer_port
    @@system_timer_port ||= MidiPort.new(self, 'SYSTEM TIMER',
                                         client_id: SND_SEQ_CLIENT_SYSTEM,
                                         port: SND_SEQ_PORT_SYSTEM_TIMER)
  end

  alias :subscribers_unknown :subscribers_unknown_port
  alias :system_timer :system_timer_port

  def open?
    @handle
  end

  # returns a hash of MidiClient instances, index by clientid
  # The result is cached, use clients! or ports! to reload
  def clients
    @clients and return @clients
    @clients = {}
    cinfo = client_info_malloc
    cinfo.client = -1
    require_relative 'midiclient'
    @clients[cinfo.client] = MidiClient.new(cinfo) while @handle.next_client(cinfo)
    @client = @clients[@client_id]
    @clients
  end

  # See #clients, this version always loads the clients anew
  def clients!
    @clients = nil
    clients
  end

  # return a has of MidiPorts, indexed by portname
  # The result is cached, used ports! to force a reload (also of clients)
  def ports
    return @ports if @ports
    @ports = {}
    @ports_index = {}
    require_relative 'midiport'
    for clientid in clients.keys
      pinfo = port_info_malloc
      pinfo.client = clientid
      pinfo.port = -1
      while @handle.next_port(pinfo)
# BAD IDEA         next unless (pinfo.type & SND_SEQ_PORT_TYPE_MIDI_GENERIC) &&
#                        pinfo.capability & (SND_SEQ_PORT_CAP_READ | SND_SEQ_PORT_CAP_SUBS_READ) ==
#                          (SND_SEQ_PORT_CAP_READ | SND_SEQ_PORT_CAP_SUBS_READ)
        (@ports_index[clientid] ||= {})[pinfo.port] = @ports[pinfo.name] = MidiPort.new(self, pinfo)
        # This assumes that pinfo.name is somehow unique?  Well, it seems to be
      end
    end
    @ports
  end

  # See #ports.
  # Refreshes @ports, @clients and @client
  def ports!
    @clients = @ports = nil
    ports
  end
end # Sequencer

end # RRTS
