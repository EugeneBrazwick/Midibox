
require_relative 'rrts'
require_relative 'midievent'
require 'forwardable'

module RRTS

class Sequencer
include Driver # open up namespace
extend Forwardable
  # for 'new':
  Duplex = SND_SEQ_OPEN_DUPLEX
  InputOnly = SND_SEQ_OPEN_INPUT
  OutputOnly = SND_SEQ_OPEN_OUTPUT
  Blocking = false
  NonBlocking = true
private
=begin
   Sequencer.new name, [params] [ block]
  parameters:
    client_name - name of the instantiated client, if nil no client will be instantiated
    params - hash of optional parameters:
      name - default 'default'
      openmode - default Duplex
      clientname - unset
      map_ports - default true if clientname yields true
      blockingmode - default Blocking
    block - encapsulation for automatic close. Works like IO::open.
=end
  def initialize client_name = nil, params = nil, &block
    @client = @handle = nil
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

=begin
Sequencer open name, [params] [ block]
parameters:
  client_name - name of the instantiated client, if nil no client will be instantiated
  params - hash of optional parameters:
  name - default 'default'
  openmode - default Duplex
  clientname - unset
  map_ports - default true if clientname yields true
  blockingmode - default Blocking
  block - encapsulation for automatic close. Works like IO::open.

Only call this after a close, if you want to reopen it.
Just use 'new'.
=end
  def open client_name = nil, params = nil
    close
    name = 'default'
    openmode = Duplex
    blockingmode = Blocking
    map_ports = client_name
    if params
      for key, value in params
        case key
        when :name then name = value
        when :openmode then openmode = value
        when :blockingmode then blockingmode = value
        when :clientname then clientname = value
        when :map_ports then map_ports = value
        else
          raise RRTSError.new("Illegal parameter '#{key}' for Sequencer")
        end
      end
    end
    @handle = snd_seq_open name, openmode, blockingmode
    begin
      @handle.client_name = client_name if client_name
      @client_id = @handle.client_id
      ports! if map_ports
      @client = clients[@client_id]  # ports! is not necessarily called!
      if block_given?
        begin
          yield self
        ensure
          close
        end
      end
    rescue
      close
      raise
    end
  end

  # close
  # closes the sequencer. Must be called to free resources, unless a block is passed to 'new'
  def close
    return unless @handle
    @handle.close
    @handle = @client = @client_id = @ports = @ports_index == @clients = nil
  end

  # MidiClient client. us.
  attr :client
  # int client_id. Same as client.client
  attr :client_id

  # client_name = newname
  def client_name= arg
    @client.name = @handle.client_name = arg
  end
=begin  hmm... would have been nice but cannot possibly work
  Klassmap = { :clock=>ClockEvent, :note=>NoteEvent, :keypress=>NoteEvent,
               :noteon=>NoteOnEvent, :noteoff=>NoteOffEvent,
               :controller=>ControllerEvent,
               :pgmchange=>ProgramChangeEvent,
               :sysex=>SystemExclusiveEvent
             }
=end
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

=begin
  MidiEvent, more event_input

  retrieve an event from sequencer

Returns:

  Obtains a MidiEvent from sequencer.
  This function firstly receives the event byte-stream data from sequencer as much as possible at once.
  Then it retrieves the first event record.
  By calling this function sequentially, events are extracted from the input buffer.
  If there is no input from sequencer, function falls into sleep in blocking mode until an event is received,
  or returns nil in non-blocking mode. Occasionally, it may raise ENOSPC error. This means that the input
  FIFO of sequencer overran, and some events are lost. Once this error is returned, the input FIFO is cleared automatically.

  Function returns the event plus a boolean indicating more bytes remain in the input buffer
  Application can determine from the returned value whether to call input once more or not,
      if there's more data it will probably(!) not block, even in blocking mode.

=end
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

  # Access to level lower.  PRUNE THIS ASAP!
  def_delegators :@handle, :poll_descriptors, :poll_descriptors_count, :poll_descriptors_revents,
                 :drain_output, :start_queue, :nonblock, :alloc_named_queue, :set_queue_tempo,
                 :set_output_buffer_size, :output_buffer_size,
                 :set_input_buffer_size, :input_buffer_size, :sync_output_queue,
                 :create_port, :event_output, :connect_from, :connect_to, :queue_status

  # this means a sequencer behaves a lot like a client
  def_delegator :@client, :name, :client_name
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
#     puts "#{File.basename(__FILE__)}:#{__LINE__}:parse_address(#{portspec.inspect})"
    midiport = ports[portspec] and return midiport
#     puts "#{File.basename(__FILE__)}:#{__LINE__}:parse_address(#{portspec.inspect})"
    port(@handle.parse_address(portspec))
  end

  # MidiPort port_with_id clientid, portid
  # The port must exist
  def port clientid, portid = nil
    case clientid when Array then clientid, portid = clientid end
    t = @ports_index[clientid]
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

  # The special port 254:253
  def subscribers_unknown_port
    @@subscribers_unknown_port ||= MidiPort.new(self, 'SUBSCRIBERS UNKNOWN',
                                                port: SND_SEQ_ADDRESS_SUBSCRIBERS,
                                                client_id: SND_SEQ_ADDRESS_UNKNOWN)
  end

  alias :subscribers_unknown :subscribers_unknown_port

  def open?
    @handle
  end

  # MidiClient[clientid] clients
  # The result is cached, use clients! or ports! to reload
  def clients
    return @clients if @clients
    @clients = {}
    cinfo = snd_seq_client_info_malloc
    cinfo.client = -1
    require_relative 'midiclient'
    @clients[cinfo.client] = MidiClient.new(cinfo) while @handle.next_client(cinfo)
    @client = @clients[@client_id]
    @clients
  end

  # MidiClient[clientid] clients!
  # Refresh the cache and also @client
  def clients!
    @clients = nil
    clients
  end

  # MidiPort[portname (?!)] ports
  # The result is cached, used ports! to force a reload (also of clients)
  def ports
    return @ports if @ports
    @ports = {}
    @ports_index = {}
    require_relative 'midiport'
    for clientid in clients.keys
      pinfo = snd_seq_port_info_malloc
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

  # MidiPort[portname] ports!
  # Refreshes @ports, @clients and @client
  def ports!
    @clients = @ports = nil
    ports
  end
end # Sequencer

end # RRTS
