
# Copyright (c) 2010 Eugene Brazwick

require_relative 'driver/alsa_midi.so'
require 'forwardable'
require_relative 'rrts'

module RRTS

# Subscription can be used as a virtual connection between two ports.
# It helps setting parameters on events that are connection dependend
# like sender and destination
  class Subscription
    include Driver

    private

      # Parameters:
      # [sequencer] owner, a Sequencer
      # [seq_handle] handle of +sequencer+
      # [sender] a MidiPort
      # [receiver] a MidiPort
      # [options] optional hash with valid keys:
      #           [:any_subscribers] boolean. If true  the events are sent to 'any subscribers' on the connection
      #
      # Please use Sequencer#subscribe instead.
      def initialize sequencer, seq_handle, sender, receiver, options
        @sequencer, @seq_handle = sequencer, seq_handle
        @sender, @receiver = sender, receiver
        @any_subscribers = false
        @handle = port_subscribe_malloc
        @handle.sender, @handle.dest = @sender, @receiver
        options and
          options.each do |key, value|
            case key
            when :any_subscribers then @any_subscribers = value
            when :exclusive then @handle.exclusive = value
            when :time_update then @handle.time_update = value
            when :time_real then @handle.time_real = value
            when :queue then @handle.queue = value.id
            else raise RRTSError, "invalid subscription option '#{key}'"
            end
          end
        @seq_handle.subscribe_port @handle
      end

    public

      # embellish the event with the correct data
      def << event
        event.source = @sender
#         tag "Setting dest to #{@any_subscribers ? @sequencer.any_subscribers : @receiver}"
        event.dest = @any_subscribers ? @sequencer.any_subscribers : @receiver
        @sequencer << event
        self # !!!!!!!!
      end
  end
end
