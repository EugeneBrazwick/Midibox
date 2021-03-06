
require_relative 'rrts'
require_relative 'midievent'
require 'forwardable'

module RRTS

  # This class is the main client for the Alsa MIDI system.
  # It is possible to use more than one Sequencer within an application
  #
  # Delegates to:
  # *  Driver::AlsaSequencer_i#poll_descriptors
  # *  Driver::AlsaSequencer_i#poll_descriptors_count
  # *  Driver::AlsaSequencer_i#poll_descriptors_revents
  # *  Driver::AlsaSequencer_i#drain_output,  with alias +flush+
  # *  Driver::AlsaSequencer_i#start_queue
  # *  Driver::AlsaSequencer_i#nonblock
  # *  Driver::AlsaSequencer_i#alloc_named_queue,  but please use RRTS::MidiQueue::new
  # *  Driver::AlsaSequencer_i#set_queue_tempo
  # *  Driver::AlsaSequencer_i#queue_tempo
  # *  Driver::AlsaSequencer_i#name
  # *  Driver::AlsaSequencer_i#set_queue_info
  # *  Driver::AlsaSequencer_i#queue_info
  # *  Driver::AlsaSequencer_i#output_buffer_size
  # *  Driver::AlsaSequencer_i#output_buffer_size=
  # *  Driver::AlsaSequencer_i#input_buffer_size
  # *  Driver::AlsaSequencer_i#input_buffer_size=
  # *  Driver::AlsaSequencer_i#sync_output_queue
  # *  Driver::AlsaSequencer_i#create_port, please use RRTS::MidiPort::new
  # *  Driver::AlsaSequencer_i#event_output
  # *  Driver::AlsaSequencer_i#event_output_buffer
  # *  Driver::AlsaSequencer_i#event_output_direct
  # *  Driver::AlsaSequencer_i#queue_status
  # *  Driver::AlsaSequencer_i#remove_events
  # *  Driver::AlsaSequencer_i#client_pool
  # *  Driver::AlsaSequencer_i#client_pool=
  # *  Driver::AlsaSequencer_i#client_pool_output=
  # *  Driver::AlsaSequencer_i#client_pool_output_room=
  # *  Driver::AlsaSequencer_i#client_pool_input=
  # *  Driver::AlsaSequencer_i#reset_pool_input
  # *  Driver::AlsaSequencer_i#reset_pool_output
  # *  Driver::AlsaSequencer_i#system_info
  # *  Driver::AlsaSequencer_i#dump_notes=
  # *  Driver::AlsaClientInfo_i#broadcast_filter?
  # *  Driver::AlsaClientInfo_i#error_bounce?
  # *  Driver::AlsaClientInfo_i#event_lost
  # *  Driver::AlsaClientInfo_i#events_lost
  # *  Driver::AlsaClientInfo_i#num_ports
  # *  Driver::AlsaClientInfo_i#type
  # *  Driver::AlsaClientInfo_i#name through +client_name+
  # *  Driver::AlsaSystemInfo_i#cur_clients
  # *  Driver::AlsaSystemInfo_i#cur_queues
  #
  # The sequencer also stores some global entities, like the list of ports on the
  # system. Even though not a MidiClient, the Sequencer has access to the client
  # information methods like +events_lost+ etc..
  #
  # Context: you would normally use it like this:
  #
  #    Sequencer.new('myseq') do |seq|
  #       ...
  #    end # closed automatically
  #
  # ===== And then?
  #
  # Alsa has a particular paradigm. It uses a 'clients' and 'ports' system where clients
  # (like Sequencer is) 'publish' ports for other applications to see.
  # You can then connect these ports to make the messages they send flow from one client
  # to another.
  #
  # So you cannot just open another clients port and write to it. What you must do is
  # to create an input- and outputport for your client. Then you can connect these ports
  # with two external ports of your choice. The fun part is that these connections can also
  # be made by external programs, like +aconnect+
  # To connect two ports you use MidiPort#connect_to and MidiPort#connect_from
  # When that is done events can be created and after explicitely setting the sender (your port)
  # and the receiver (the external port) you can finally send the event to the sequencer.
  #
  # ====== Working example of an event reader:
  #
  #           MY_PORTNAME = 'UM-2 MIDI 1'  # To find out the proper name use 'aconnect -o'
  #           require 'rrts/sequencer'
  #           include RRTS
  #           Sequencer.new('example') do |sequencer|
  #             MidiPort.new(sequencer, "example port", write: true,
  #                           subscription_write: true,
  #                           midi_generic: true, application: true, midi_channels: 16) do |port|
  #               port.connect_from sequencer.ports[MY_PORTNAME] # optional, you can also use 'kaconnect' to do this for you!
  #               loop do
  #                 puts sequencer.event_input.to_s
  #               end
  #             end
  #           end
  #
  # The input port constructor passes flags 'write' and 'subscription_write'.
  # This seems counter-intuitive but we want to let the other clients know they can write to this port.
  # So it means 'you can write', and not 'I want to write'.
  #
  # Note that you will probably be flooded with RRTS::ClockEvent instances so it may be a good idea
  # to filter those out, or switch off the clock on your keyboard.
class Sequencer
  include Driver # open up namespace
  extend Forwardable
    # for ::new.  Please use :duplex
    Duplex = SND_SEQ_OPEN_DUPLEX
    # for ::new. Use :inputonly
    InputOnly = SND_SEQ_OPEN_INPUT
    # for ::new, Use :outputonly
    OutputOnly = SND_SEQ_OPEN_OUTPUT

    # for ::new, Please use :blocking instead
    Blocking = false
    # for ::new, Please use :nonblocking instead
    NonBlocking = true

    # for the poll methods
    PollIn = POLLIN
    # for the poll methods
    PollOut = POLLOUT
  #   POLLTIME = 0.01 # 10 ms

    # hash with *open* sequencers, indexed by client_name
    @@sequencers = {}

  private

  # Create a new sequencer
  #
  # Parameters:
  # [client_name] name of the instantiated client, if nil no client will be instantiated ie,
  #               the sequencer will be nameless and cannot be seen by other Alsa clients.
  # [params] hash of optional parameters:
  #          [name]         default 'default'. Do not alter. This is *not* the client_name
  #          [openmode]     default :duplex, can also be :inputonly or :outputonly
  #          [map_ports]    default true if client_name is passed as first argument
  #          [blockingmode] default :blocking, can also be :nonblocking
  #          [dump_notes]   if true dump to stderr and do NOT play them!! Only works with HACKED cpp
  #                         backend
  #          [polltime]     timeout in seconds for sleep, for nonblockingmode, default is 0.01
  #                         If left nil methods will currently fail.
  # [block] encapsulation for automatic close. Works like IO::open.
  #
    def initialize client_name = nil, params = nil, &block
      @client = @handle = nil
      @client_id = @ports = @ports_index = @clients = nil  # not guaranteed open does this
      @queues = @opened_ports = nil
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

    OpenModeMap = { duplex: SND_SEQ_OPEN_DUPLEX, inputonly: SND_SEQ_OPEN_INPUT, outputonly: SND_SEQ_OPEN_OUTPUT }
    BlockingModeMap = { blocking: Blocking, nonblocking: NonBlocking }

  # See Sequencer#new. Please use that.
  # Only call this after a close, if you want to reopen it.
    def open client_name = nil, params = nil
      close
      name = 'default'
      openmode, blockingmode = SND_SEQ_OPEN_DUPLEX, Blocking
      map_ports = client_name
      dump_notes = false
      @polltime = 0.01
      if params
        for key, value in params
          case key
          when :name then name = value
          when :openmode then openmode = Symbol === value ? (OpenModeMap[value] || SND_SEQ_OPEN_DUPLEX) : value
          when :blockingmode then blockingmode = Symbol === value ? (BlockingModeMap[value] || Blocking) : value
          # the next entry seems to be some hack? It makes it possible of storing all constructor
          # parameters in a single hash... Except that +map_ports+ is no longer set.
          when :client_name, :clientname then client_name = value
          when :map_ports then map_ports = value
          when :dump_notes then dump_notes = true
          when :polltime then @polltime = value
          else
            raise RRTSError.new("Illegal parameter '#{key}' for Sequencer")
          end
        end
      end
      @handle = seq_open name, openmode, blockingmode
      begin
        @handle.dump_notes = true if dump_notes
        if client_name
          @handle.client_name = client_name
          @@sequencers[client_name] = self
        end
        @client_id = @handle.client_id
        ports! if map_ports
        @client = clients[@client_id]  # ports! is not necessarily called!
        if block_given?
          begin
            yield self
          ensure
  #           tag "ensure close"
            close
          end
        end
      rescue
        close
        raise
      end
    end

    # closes the sequencer. Must be called to free resources.
    # This is normally automatically called if you pass a block to the constructor
    def close
      return unless @handle
      if @opened_ports
        t, @opened_ports = @opened_ports, nil
        t.each_value { |port| port.close }
      end
      if @queues
        t, @queues = @queues, nil
        t.each_value { |queue| queue.free }
      end
      client_name = @client.name and @@sequencers.delete(client_name)
      t = @handle
      @handle = nil
      t.close
      @client = @client_id = @ports = @ports_index = @clients = nil
      @queues = nil
    end

    # client_name = newname
    def client_name= arg
      name = @client.name and @@sequencers.delete(name)
      @client.name = @handle.client_name = arg
      @@sequencers[arg] = self
    end

    Klassmap = { SND_SEQ_EVENT_CLOCK=>ClockEvent, SND_SEQ_EVENT_NOTE=>NoteEvent,
                SND_SEQ_EVENT_KEYPRESS=>NoteEvent,
                SND_SEQ_EVENT_NOTEON=>NoteOnEvent, SND_SEQ_EVENT_NOTEOFF=>NoteOffEvent,
                SND_SEQ_EVENT_CONTROLLER=>ControllerEvent,
                SND_SEQ_EVENT_PGMCHANGE=>ProgramChangeEvent,
                SND_SEQ_EVENT_PITCHBEND =>PitchbendEvent,
                SND_SEQ_EVENT_CHANPRESS=>ChannelPressureEvent,
                # SND_SEQ_EVENT_CONTROL14=>Control14Event,  there is no such event
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

  # Returns a MidiEvent
  #
  # Obtains a MidiEvent from the sequencer.
  # This function firstly receives the event byte-stream data from sequencer as much as possible at once.
  # Then it retrieves the first event record.
  # By calling this function sequentially, events are extracted from the input buffer.
  # If there is no input from sequencer, function falls into sleep in blocking mode until
  # an event is received,
  # or it raises Errno::EAGAIN in non-blocking mode (not the default mode).
  #
  # Occasionally, it may raise an Errno::ENOSPC error. This means
  # that the input FIFO of sequencer overran, and some events are lost.
  # Once this error is returned, the input FIFO is cleared automatically.
  #
    def event_input
  #     tag "Calling event_input"
      ev = @handle.event_input
  #     tag "received event #{ev.typeid}"
  #     typeid = ev.typeid
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
      (Klassmap[ev.type] || MidiEvent).new(self, ev)
    end

    def_delegators :@handle, :poll_descriptors, :poll_descriptors_count, :poll_descriptors_revents,
                  :start_queue, :nonblock, :name,
                  # do not use alloc_named_queue, but say 'MidiQueue.new'
                  :alloc_named_queue,
                  :set_queue_tempo, :queue_tempo,
                  :set_queue_info, :queue_info,
                  :output_buffer_size=, :output_buffer_size,
                  :input_buffer_size=, :input_buffer_size, :sync_output_queue,
                  :create_port, :event_output, :queue_status,
                  :event_output_buffer, :event_output_direct,
                  :remove_events, :client_pool, :client_pool=, :client_pool_output=,
                  :client_pool_output_room=, :client_pool_input=, :reset_pool_output,
                  :reset_pool_input, :system_info, :dump_notes=,
                  :next_client, :next_port, :query_next_client, :query_next_port

    # the following two are here for completeness sake. Please use the MidiPort methods instead!
    def_delegators :@handle, :connect_from, :connect_to

    # this means a sequencer behaves a lot like a client
    #def_delegator :@client, :client_name, :name  CONFLICTS with 'name == default'... COnfusing
    def_delegators :@client, :broadcast_filter?, :error_bounce?, :event_lost, :events_lost,
                            :num_ports, :type

    def_delegator :@client, :name, :client_name

    # in blocking mode the same as Driver::AlsaSequencer_i#drain_output.
    # in nonblocking mode it may go to sleep until the output is drained.
    # Therefore it always blocks.
    def drain_output
      loop do
        begin
          return @handle.drain_output
        rescue Errno::EAGAIN
          sleep(@polltime)
        end
      end
  #     loop do
  # this now fails since the sleep is placed inside drain_output
  # Unfortunately drain_output seems to block signals....
  #       r = @handle.drain_output and return r
  #       raise RRTSError.new('flush failed: resource temporarily unavailable') unless @polltime
  #       tag "polling operational!!"
  #       sleep @polltime
  #     end
    end

    # drain_output is just a flush, so let's support that name:
    alias :flush :drain_output

    # Same as event_output, except for the returnvalue (self).
    def << event
  #     tag "<< #{event.inspect}"
      if FlushEvent === event
        @handle.drain_output
      else
        @handle.event_output event
      end
      self
    end

    # MidiPort parse_address string. In addition to '0:0' or 'UM-2:1' we also understand 'UM-2 PORT2'
    # May throw AlsaMidiError if the port is invalid or does not exist
    def parse_address portspec
      if portspec.respond_to?(:to_ary)
        port(portspec.to_ary)
      else
  #     puts "#{File.basename(__FILE__)}:#{__LINE__}:parse_address(#{portspec.inspect}),ports=#{ports.keys.inspect}"
        midiport = ports[portspec] and return midiport
  #     puts "#{File.basename(__FILE__)}:#{__LINE__}:parse_address(#{portspec.inspect})"
        port(@handle.parse_address(portspec))
      end
    end

    # Returns the specified port, the port must exist or an AlsaMidiError is raised
    # Port can be given as a splat or tuple of client + portid, or as a string.
    # Also the special symbols :subscribers_unknown and :system_timer are resolved here.
    def port clientid, portid = nil
      case clientid
      when Array then return port(clientid[0], clientid[1])
      when Regexp
        ports.each { |name, value| return value if name =~ clientid }
        raise AlsaMidiError, "no port matches #{clientid}\n" +
                            "ports = #{ports.keys.inspect}"
      when String
        return parse_address(clientid) unless portid
      when :subscribers_unknown then return subscribers_unknown
      when :system_timer then return system_timer
      when :full_broadcast then return full_broadcast
      when :system_announce then return system_announce
      end
      t = @ports_index && @ports_index[clientid]
      unless t && t[portid]
        ports!
        t = @ports_index[clientid]
        unless t && t[portid]
          raise AlsaMidiError, "Internal error, port #{clientid}:#{portid} not located\n" +
                              "ports = #{ports.map{|k,v| v.full_name}.inspect}"
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

    # The special port 255:255
    def full_broadcast_port
      @@full_broadcast_port ||= MidiPort.new(self, 'FULL BROADCAST',
                                            client_id: SND_SEQ_ADDRESS_BROADCAST,
                                            port: SND_SEQ_ADDRESS_BROADCAST)
    end

    # The special port 0:0
    def system_timer_port
      @@system_timer_port ||= MidiPort.new(self, 'SYSTEM TIMER',
                                          client_id: SND_SEQ_CLIENT_SYSTEM,
                                          port: SND_SEQ_PORT_SYSTEM_TIMER)
    end

    # The special port 0:1
    def system_announce_port
      @@system_announce_port ||= MidiPort.new(self, 'SYSTEM ANNOUNCE',
                                              client_id: SND_SEQ_CLIENT_SYSTEM,
                                              port: SND_SEQ_PORT_SYSTEM_ANNOUNCE)
    end

    # a shortcut
    alias :subscribers_unknown :subscribers_unknown_port

    # a shortcut
    alias :any_subscribers :subscribers_unknown_port

    # a shortcut
    alias :system_timer :system_timer_port

    alias :system_announce :system_announce_port
    alias :full_broadcast :full_broadcast_port

    # returns true if the sequencer is currently open
    # it would be weird if it returned false
    def open?
      @handle
    end

    # returns a hash of MidiClient instances, index by clientid
    # The result is cached, use clients! or ports! to force a fetch
    def clients
      @clients and return @clients
      @clients = {}
      cinfo = client_info_malloc
      cinfo.client = -1
      require_relative 'midiclient'
      @clients[cinfo.client] = MidiClient.new(self, cinfo) while @handle.next_client(cinfo)
      @client = @clients[@client_id]
      @clients
    end

    # See #clients, this version always loads the clients anew
    def clients!
      @clients = nil
      clients
    end

    # return a hash(not an array!!) of MidiPorts, indexed by portname (a string)
    # The result is cached, use ports! to force a reload
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

    # Create a queue with given name, plus options
    # See RRTS::MidiQueue::new
    # Important, a queue created using this method is automatically freed when
    # the sequencer closes.
    # The queuename should be unique however.
    # The MidiQueue is returned
    def create_queue queuename, options = nil
      require_relative 'midiqueue'
  #     tag "create_queue options=#{options.inspect}"
      (@queues ||= {})[queuename] = MidiQueue.new(self, queuename, options)
    end

    # create a port, see RRTS::MidiPort::new
    # these ports are automatically closed when the sequencer closes
    # Returns the MidiPort created
    def create_port portname, options = nil
      require_relative 'midiport'
      @opened_ports[portname].close if @opened_ports && @opened_ports[portname]
      @ports = nil # invalidate cache
      (@opened_ports ||= {})[portname] = MidiPort.new(self, portname, options)
    end

    # called by aQueue.name = newname.
    def rename_queue aQueue, newname
      @queues.delete[aQueue.name]
      info = aQueue.info
      info.name = newname
      set_queue_info aQueue, info
      @queues[aQueue.name] = aQueue
    end

    # return the queue with the given name. Bit boring since most apps only have 1 queue
    # The queue must exist
    def queue name
      @queues && @queues[name] or
        raise RRTSError.new("Queue '#{name}' does not exist")
    end

    # without argument return MidiClient which is us, otherwise locate client with that name
    # or with that id, if numeric (or numeric string)
    # Note however that prefixing zeroes is not smart and will not work as expected
    def client name = nil
      return @client if name.nil?
      if Integer === name || name =~ /^\d+$/
        id = Integer(name)
        r = clients[id] || clients![id] and return r
      else
        r = clients.find{|dummy, c| c.name == name } and return r[1]
        r = clients!.find{|dummy, c| c.name == name } and return r[1]
      end
      raise RRTSError.new("client '#{name}' not located")
    end

    # us, an integer client_id. Same as client.client
    attr :client_id

    alias :id :client_id

    # returns a hash, indexed by queuename. So queue(name) == queues[name]
    attr :queues

    # float, polltime in seconds
    attr :polltime

    def_delegators :system_info, :cur_clients, :cur_queues

    # subscribe to pairs passed in hash. Like:
    #
    #    seq.subscribe sender1=>receiver1, ....
    #
    # Both sender and receiver are MidiPort instances
    #
    #    seq.subscribe any_subscribers: true, more_opts: ..., sender1=>receiver1 ,....
    #
    # returns an array with Subscription instances, except when it is a single one
    # where the Subscription is returned as is.
    # You can now send events to the Subscription (using the << operator) and this will automatically
    # set the sender and receiver of the event.
    #
    # Valid options are:
    # [:any_subscribers] bool, send events to all subscribers
    # [:queue] MidiQueue. Use this queue
    # [:time_real] bool. Default false, indicates times must be converted to real_time
    #              If unset, and +time_update+ is true, then timestamps use ticks (pulses).
    # [:time_update] bool. Default false, indicates that timestamps must be used.
    # [:exclusive] bool. Default false. If set others can no longer create the same connection.
    def subscribe options_plus_senders_plus_receivers
      result = []
      require_relative 'subscription'
      opts = nil
      options_plus_senders_plus_receivers.each do |sender, receiver|
        if Symbol === sender
          raise RRTSError, 'Illegal order, options go before ports' unless result.empty?
          (opts ||= {})[sender] = receiver
        else
          result << Subscription.new(self, @handle, sender, receiver, opts)
        end
      end
      result.length == 1 ? result[0] : result
    end

    # returns the *opened* sequencer with that name ie, the sequencer must have been created with a name,
    # and it must not be closed yet.
    def self.[](name)
      @@sequencers[name]
    end
end # Sequencer

end # RRTS