#!/usr/bin/ruby1.9.1 -w
# encoding: utf-8

require_relative 'driver/alsa_midi.so'
require 'forwardable'

module RRTS

# MidiPort
# This class represents a queried or created port. A port is a connection
# to another MIDI device, or a software application (but basically another sequencer).
#
# The following (readonly) delegates exist
# * Driver::AlsaPortInfo_i#type
# * Driver::AlsaPortInfo_i#name
# * Driver::AlsaPortInfo_i#capability
# * Driver::AlsaPortInfo_i#timestamping?
# * Driver::AlsaPortInfo_i#timestamp_queue
# * Driver::AlsaPortInfo_i#timestamp_real?
# * Driver::AlsaPortInfo_i#midi_channels
# * Driver::AlsaPortInfo_i#midi_voices
# * Driver::AlsaPortInfo_i#synth_voices
# * Driver::AlsaPortInfo_i#port_specified?
#
# To retrieve external port info for querying use Sequencer#port
class MidiPort
include Comparable
include Driver
extend Forwardable

  CapsBitsMap = {
                  :read => SND_SEQ_PORT_CAP_READ,
                  :write => SND_SEQ_PORT_CAP_WRITE,
                  :duplex=> SND_SEQ_PORT_CAP_DUPLEX,
                  :subs_read=> SND_SEQ_PORT_CAP_SUBS_READ,
                  :subs_write=> SND_SEQ_PORT_CAP_SUBS_WRITE,
                  :subscription_read=> SND_SEQ_PORT_CAP_SUBS_READ,
                  :read_subscription=> SND_SEQ_PORT_CAP_SUBS_READ,
                  :subscription_write=> SND_SEQ_PORT_CAP_SUBS_WRITE,
                  :write_subscription=> SND_SEQ_PORT_CAP_SUBS_WRITE,
                  :no_export=> SND_SEQ_PORT_CAP_NO_EXPORT
                }
  TypeBitsMap = {
    :specific => SND_SEQ_PORT_TYPE_SPECIFIC,
    :hardware_specific => SND_SEQ_PORT_TYPE_SPECIFIC,
    :midi_generic=> SND_SEQ_PORT_TYPE_MIDI_GENERIC,
    :midi_gm=> SND_SEQ_PORT_TYPE_MIDI_GM,
    :midi_gm2=> SND_SEQ_PORT_TYPE_MIDI_GM2,
    :midi_gs=> SND_SEQ_PORT_TYPE_MIDI_GS,
    :midi_xg=> SND_SEQ_PORT_TYPE_MIDI_XG,
    :midi_mt32 => SND_SEQ_PORT_TYPE_MIDI_MT32,
    :direct_sample=> SND_SEQ_PORT_TYPE_DIRECT_SAMPLE,
    :sample=> SND_SEQ_PORT_TYPE_SAMPLE,
    :hardware=> SND_SEQ_PORT_TYPE_HARDWARE,
    :software=> SND_SEQ_PORT_TYPE_SOFTWARE,
    :synth=> SND_SEQ_PORT_TYPE_SYNTH,
    :synthesizer=> SND_SEQ_PORT_TYPE_SYNTHESIZER,
    :connects_to_device=> SND_SEQ_PORT_TYPE_PORT,
    :application=> SND_SEQ_PORT_TYPE_APPLICATION
  }

private

  AllowedParams = {:timestamping=>:timestamping=, :timestamp_queue=>:timestamp_queue=,
                   :timestamp_real=>:timestamp_real=, :midi_channels=>:midi_channels=,
                   :midi_voices=>:midi_voices=, :synth_voices=>:synth_voices=,
                   :port=>:port=, :port_specified=>:port_specified=,
                   :client_id=>:client_id=
                  }

# Open a new port.
#
# Parameters:
# [sequencer] owning Sequencer
# [name]      name of the port to be
# [params] a hash with any one of the following symbols (use 'true' as value):
#          (Example: midi_generic: true, duplex: true )
#          [:read] true, to announce read capabilities
#          [:write] true, similar
#          [:duplex] true, read  + write
#          [:subs_read] true, to announce support of subscriptions for reading
#          [:subs_write] true, similar
#          [:subscription_read] same as subs_read, since I don't understand the name
#          [:read_subscription] ""
#          [:subscription_write] similar
#          [:write_subscription] ""
#          [:no_export] others may not subscribe to this port
#          [:specific] uses device specific messages
#          [:hardware_specific] better name for specific
#          [:midi_generic] announce generic (any) MIDI support
#          [:midi_gm] true, for general MIDI support
#          [:midi_gm2] general MIDI 2 support
#          [:midi_gs] compatible with Roland GS standard
#          [:midi_xg] compatible with Yamaha XG standard
#          [:midi_mt32] compatible with Roland MT32
#          [:direct_sample] instruments can be downloaded to this port, but not throug a queue
#          [:sample] instruments can be downloaded to this port, even through a queue
#          [:hardware] this port is implemented in hardware
#          [:software] it is not implemented in hardware
#          [:synth] supports SAMPLE events (alsa(?) not MIDI)
#          [:synthesizer] generates waves
#          [:connects_to_device] this port connects to another device (SND_SEQ_PORT_TYPE_PORT)
#                                Note that 'port' is the portnumber and this name is confusing anyway
#          [:application] if port belongs to an application like a sequencer
#          [:timestamping] put timestamps on events, provided there is also a queue
#          [:timestamp_queue] for timestamping, either an int or a MidiQueue
#          [:timestamp_real] for timestamping in realtime (nanoseconds), default is in ticks
#                            where tick 0 is when the queue starts (though you can force absolute ticks -- somewhere?)
#          [:midi_channels] number of midi channels supported
#          [:midi_voices] number of midi voices supported, may leave this 0
#          [:synth_voices] number of synth voices supported, may leave this 0
#          [:port] portnumber to use, sets port_specified as well
#          [:port_id] same as +port+
#          [:broadcast] makes this port a pseudo port, to broadcast to all ports within the client.
#          [:port_specified] passed on as is, might be overwritten by setting port, so do not use this.
#          [:simple] true, make it a simple port without buffering or queueing
#          [:direct] same as +simple+
# Alternatively you can pass all boolean symbols in an array of symbols.
#
# *Note*: this method can also be used to 'pick up' a port, however you should use Sequencer#port and
# Sequencer#ports for that.
  def initialize sequencer, name, *params, &block
    @handle = nil
    @simple = false
    open sequencer, name, *params, &block
  end

  def initialize_copy other
    @handle = other.copy_to_i
  end

protected
  def copy_to_i handle
    @handle.copy_to(handle) if @handle
  end

public

  # see MidiPort::new. Can be used to reopen a port
  def open sequencer, name, *params
    close
    @sequencer = sequencer
    @seq_handle = sequencer && sequencer.instance_variable_get(:@handle)
    if params.length == 1 && Hash === params[0]
      params = params[0]
    elsif !params.empty?
      t = params
      params = {}
      t.each {|symbol| params[symbol] = true }
    else
      params = nil
    end
    if params and params[:client_id]
      params[:port] = SND_SEQ_ADDRESS_BROADCAST  if params[:broadcast]
      @client_id = params[:client_id]
      @port = params[:port] || params[:port_id]
      # sort of lightweight portref.  It can be used to connect
      # but it is not open
      return self
    end
    unless name.respond_to?(:to_str)
      # supposedly: 'name' == portinfo
      @handle = name.copy_to
      @client_id = @handle.client
      @port = @handle.port # int
    else
      capsbits = typebits = 0
      @client_id = sequencer.client_id
      @simple = false
      @port = nil
      if params
        params[:port] = SND_SEQ_ADDRESS_BROADCAST  if params[:broadcast]
        for k, v in params
          case k
          when :simple, :direct
            raise RRTSError.new("Invalid parameters specified for simple MidiPort") if @handle
            @simple = v
          when :port, :port_id
#             tag "port #{v} supplied by user"
            @port = v
          else
            if lu = CapsBitsMap[k]
              capsbits |= lu
            elsif lu = TypeBitsMap[k]
              typebits |= lu
            elsif lu = AllowedParams[k]
              raise RRTSError.new("Invalid parameter '#{k}' for simple MidiPort") if @simple
              @handle ||= port_info_malloc
              @handle.send(lu, v)
            else
              raise RRTSError.new("Invalid parameter '#{k}' for MidiPort")
            end
          end
        end
      end
      if @simple
        @port = @seq_handle.create_simple_port(name, capsbits, typebits)
      else
        @handle ||= port_info_malloc
#         tag "port=#@port"
        @handle.port_specified = @port
        @handle.port = @port if @port
        @handle.capability = capsbits
#         tag "capsbits=#{'0x%x' % capsbits}, typebits=#{'0x%x' % typebits}"
        @handle.type = typebits
#         tag "name='#{name}'"
        @handle.name = name
        @seq_handle.create_port(@handle)
        @port = @handle.port # int !
      end
      if block_given?
        begin
          yield self
        ensure
          close
        end
      end
    end
    self
  end

  # close the port.
  # If a block is passed to the constructor the port is automatically closed
  def close
    return unless @handle or @simple
    if @handle
      @handle = nil # prevent endless loop
      @seq_handle.delete_port @port
    else
      @simple = false # prevent endless loop
      @seq_handle.delete_simple_port @port
    end
    # let's help the gc:
    @handle = @seq_handle = @sequencer = nil
    @simple = false
  end

  # Returns true if the client is active (we are open)
  def open?
    @handle
  end

  # 'client' is reserved for MidiClient reference

  # the clientid, given to us, chances are this is 128
  attr :client_id

  # returns true if this is a system port
  def system?
    @client_id == 0
  end

  # the portid, either supplied or given by the system
  attr :port

  alias :id :port

  # Two port instances are the same if they have the same client- and portid
  def <=> other
    t = @client_id <=> other.client_id
    t == 0 ? (@port <=> other.port) : t
  end

  def_delegators :@handle, :type, :name, :capability, :timestamping?, :timestamp_queue,
                 :timestamp_real?, :midi_channels, :midi_voices, :synth_voices, :port_specified?

  # returns the tuple client_id + port_id
  def address
    [@client_id, @port]
  end

  alias :addr :address

  # returns a name usefull for debugging
  def to_s
    "#@client_id:#@port(#{@handle && @handle.name})"
  end

#  connect to another MidiPort
#  Create a simple connection that cannot be locked, and has no queue
#  The current port will be the sender (write)
#
#  *IMPORTANT*:
#       a.connect_to b
#  is not the same as:
#       b.connect_from a
#  Because in 1) +a+ is supposedly the active port, and in 2) it is +b+.
#  As Eugene sees it, connect_to connects to an output port to send events
#  while connect_from connects to an input port to receive events.
#  So the lefthand side is an internal port created using MidiPort#new, while
#  the righthand side is an external port which comes from Sequencer#ports (so an.
#  external port)
#
#  But not always, it is very well possible of connecting two external ports to
# each other.
  def connect_to port
    @seq_handle.connect_to self, port
  end

  # setup a connection from another MidiPort
  # Create a simple connection that cannot be locked, and has no queue
  # The current port will be the receiver (read)
  # See also MidiPort#connect_to
  def connect_from port
    @seq_handle.connect_from self, port
  end

#   alias :>> :connect_to
#   alias :<< :connect_from                     Ambiguous with sending events.

  # Returns true if *all* keys are supported
  # These keys are available:
  # [:read] can we read from the port
  # [:write] can we write to it
  # [:duplex] can we both read and write from/to it
  # [:subs_read] can you subscribe to it for reading
  # [:subscription_read] alias for :subs_read
  # [:read_subscription] preferred alias for :subs_read
  # [:subs_write] can you subscribe to it for writing
  # [:subscription_write] alias for :subs_write
  # [:write_subscription] preferred alias for :subs_write
  # [:no_export] if set this port cannot be seen by others
  def capability?(*keys)
    bits = @handle.capability
    for k in keys
      raise RRTSError.new("Invalid capability '#{k}'") unless CapsBitsMap[k]
      return false unless (bits & CapsBitsMap[k]) != 0
    end
    true
  end

  # string full_name
  # can be used to map ports. Note however that 'name' already should be capable of doing this
  # and the chance is it returns something like 'MidiThrough:MidiThrough Port-0'
  def full_name
    @sequencer.clients[@client_id].name + ':' + @handle.name
  end

  alias :fullname :full_name

  # returns true if all symbols are set (so to speak)
  # The symbols to use are :specific, :hardware_specific, :midi_generic, :midi_gm,
  # :midi_gm2, :midi_gs, :midi_xg, :midi_mt32, :direct_sample, :sample, :hardware,
  # :software,:synth, :synthesizer, :connects_to_device and :application
  # See ::new for the meaning of these.
  def type?(*keys)
    bits = @handle.type
    for k in keys
      raise RRTSError.new("Invalid type '#{k}'") unless TypeBitsMap[k]
      return false unless (bits & TypeBitsMap[k]) != 0
    end
    true
  end

  # same as type?(:read, :subscription_read)
  def input?
    type? :read, :subscription_read
  end

  # same as type?(:write, :subscription_write)
  def output?
    type? :write, :subscription_write
  end

  # true if the port is on the SYSTEM client (I believe 0)
  def system?
    @client_id == SND_SEQ_CLIENT_SYSTEM
  end

  # Returns the MidiClient instance (the owner of the port)
  def client
    @sequencer.clients[@client_id]
  end

  # int [](0 or 1)
  # Returns clientid (for 0) and portid (otherwise)
  # This to enable using the result of parse_address as either AlsaPortInfo_i as well as MidiPort.
  def []v
    v == 0 ? @client_id : @port
  end
end # MidiPort

end # RRTS
