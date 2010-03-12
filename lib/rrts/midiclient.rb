#!/usr/bin/ruby1.9.1 -w

require_relative 'driver/alsa_midi.so'
require 'forwardable'

module RRTS

  # This class represents a client, which is always a sequencer or something close to it
  # Clients can read or write events to each other through ports.
  # The Sequencer class itself basically is a special client, since it represents us.
  # The following delegators are present
  # * AlsaClientInfo_i#name
  # * AlsaClientInfo_i#broadcast_filter?
  # * AlsaClientInfo_i#error_bounce?
  # * AlsaClientInfo_i#event_lost
  # * AlsaClientInfo_i#events_lost
  # * AlsaClientInfo_i#num_ports
  # * AlsaClientInfo_i#num_open_ports
  # * AlsaClientInfo_i#type
class MidiClient
include Driver
include Comparable
extend Forwardable;
private
  # normally never used
  def initialize sequencer, cinfo
    @sequencer = sequencer
    @handle = cinfo.copy_to
    @client = cinfo.client  # naming it 'client' is confusing but required so 'respond_to :client' works!
    # name is slightly dangerous as the name can be changed  ???? It should not matter
  end

  def initialize_copy other
    @handle = other.copy_to_i
  end

protected
  def copy_to_i handle
    @handle.copy_to handle
  end

public

  # two MidiClient instances are considered to be equal if they have
  # the same clientid
  def <=> other
    @client <=> other.client
  end

  # the internal clientid
  attr :client
  def_delegators :@handle, :name, :broadcast_filter?, :error_bounce?, :event_lost, :events_lost,
                           :num_ports, :num_open_ports, :type

  # the result is an arrray with references into sequencer#@ports
  # if you require a hash, why not use sequencer.ports or port ?
  def ports
    r = []
    pinfo = port_info_malloc
    pinfo.client = @client
    pinfo.port = -1
    while @sequencer.next_port(pinfo)
      r << @sequencer.port(@client, pinfo.port)
    end
    r
  end

end

end # RRTS
