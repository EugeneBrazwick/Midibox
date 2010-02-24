#!/usr/bin/ruby1.9

# $Id: jack.rb,v 1.4 2009/06/28 20:54:59 ara Exp $

require 'rjack'

include RJack;

class JackError < RuntimeError
end

class JackClient
private
  def handleJackResult res, msg
  raise JackError.new("%s: %s%s%s%s%s" "%s%s%s%s%s" "%s\n" % [msg,
                (res & JackFailure) != 0 ? "overall failure " : "",
                (res & JackInvalidOption) != 0 ? "invalid option " : "",
                (res & JackNameNotUnique) != 0 ? "name not unique " : "",
                (res & JackServerStarted) != 0 ? "server started " : "",
                (res & JackServerFailed) != 0 ? "could not connect to jack server " : "",

                (res & JackServerError) != 0 ? "communication error " : "",
                (res & JackNoSuchClient) != 0 ? "client does not exist " : "",
                (res & JackLoadFailure) != 0 ? "could not load " : "",
                (res & JackInitFailure) != 0 ? "could not initialize client " : "",
                (res & JackShmFailure) != 0 ? "could not connect to shared memory " : "",

                (res & JackVersionError) != 0 ? "client incompatible with this version " : ""]);
  end

  def initialize name, moreargs = nil
    @registered_ports = []
    options = 0
    servername = ''
    if moreargs
      moreargs.each do |k, v|
        case k
        when :noStartServer
          options |= JackNoStartServer if v
        when :useExactName
          options |= JackUseExactName if v
        when :serverName
          servername = v
        end
      end
    end
    @data, result = jack_client_open name, options, servername
    handleJackResult(result, 'jack_client_open failed') unless @data
    if block_given?
      begin
        yield self
      ensure
        @registered_ports.each { |port| jack_port_unregister @data, port.data }
        jack_client_close @data
      end
    end
  end

public
  def ports
    jack_get_ports @data, '', '', 0;
  end

  attr_reader :data

  #please use JackPort.new
  def registerPort port; @registered_ports << port; end
end # class JackClient

class JackPort
private
  def initialize client, name, flags, type = JACK_DEFAULT_MIDI_TYPE, bufsz = 0
    @data = jack_port_register client.data, name, type, flags, bufsz
    client.registerPort self
  end
public
  attr_reader :data
end

if __FILE__ == $0
  begin
    JackClient.new('shouldfail',  noStartServer: true, useExactName: true, serverName: 'xerxes') do |client|
      puts 'opened jack!'
    end
  rescue JackError => e
   puts "#{e}"
  end
  # somehow this works, but there is no such server  ??? So what does 'servername' actually do?
#   begin
#     JackClient.new('shouldfail',  useExactName: true, serverName: 'xerxes') do |client|
#       puts 'opened jack on xerxes!'
#     end
#   rescue JackError => e
#     puts "#{e}"
#   end
  JackClient.new 'ara' do |client|
    puts 'opened jack!'
    client.ports.each { |port| puts port }
    midi_in = JackPort.new client, "midi_in", JackPortIsInput
    midi_out = JackPort.new client, "midi_out", JackPortIsOutput
    # the previous added ara:midi_in and ara:midi_out to client.ports.
    puts "ports = #{client.ports}"
  end
end
