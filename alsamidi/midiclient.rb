#!/usr/bin/ruby1.9.1 -w

require_relative 'alsa_midi.so'
require 'forwardable'

module RRTS

class MidiClient
include Driver
include Comparable
extend Forwardable;
private
  def initialize cinfo
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

  def <=> other
    @client <=> other.client
  end

  attr :client
  def_delegators :@handle, :name, :broadcast_filter?, :error_bounce?, :event_lost, :events_lost,
                           :num_ports, :num_open_ports, :type
end

end # RRTS
