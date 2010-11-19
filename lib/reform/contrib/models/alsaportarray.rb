
# Copyright (c) 2010 Eugene Brazwick

require 'reform/model'

module Reform

  # An array of Reform::AlsaPort items. Which are currently just strings.
  # Since we need a hook into alsa we use a shared sequencer for that.
  class AlsaPortArray
    include Model
    private
      def initialize parent, qtc
        require 'rrts/sequencer'
        @@seq ||= RRTS::Sequencer.new 'qtrconnect', openmode: :inputonly
        mode :read
      end

      # mode :read or :write
      def mode io
        @mode = io
        @ports = @@seq.ports.values.find_all do |p|
          p.capability?(@mode) && !p.capability?(:no_export) && p.type?(:midi_generic) && !p.system?
        end
#         tag "ports = #{@ports.inspect}"
      end

    public
      # override
      def length
        @ports.length
      end

      def row numidx
        port = @ports[numidx]
        '%d:%d %s' % [port.client_id, port.id, port.name]
      end

  end

  createInstantiator File.basename(__FILE__, '.rb'), nil, AlsaPortArray

end