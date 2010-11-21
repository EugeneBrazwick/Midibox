
# Copyright (c) 2010 Eugene Brazwick

require 'reform/model'

module Reform

  # An array of Reform::AlsaPort items. Which are currently just strings.
  # Since we need a hook into alsa we use a shared sequencer for that.
  class AlsaPortArray < AbstractModel
#     include Model
    private
      @@seq = nil
      def initialize parent, qtc
        super
        require 'rrts/sequencer'
        unless @@seq
          @@seq = RRTS::Sequencer.new 'qtrconnect', openmode: :inputonly
          @@port =  RRTS::MidiPort.new @@seq, 'qtrconnect', :write, :simple,
                                       :write_subscription, :no_export, :application
          @@subscription = @@seq.subscribe @@seq.system_announce_port=>@@port
          @@alsaAnnounceFd = @@seq.poll_descriptors(1, RRTS::Sequencer::PollIn).fd(0)
#           tag "creating Qt::SocketNotifier on fd #{@@alsaAnnounceFd}"
          @@alsaNotifier = Qt::SocketNotifier.new(@@alsaAnnounceFd, Qt::SocketNotifier::Read)
          connect(@@alsaNotifier, SIGNAL('activated(int)'), self) do |fd|
            puts "message on fd #{fd}"
            event = @@seq.event_input # eat the event
            puts "got event #{event.inspect}"
            transaction do |tran|
              # ...
              cur_mode, @mode = @mode, nil
              # now reread the @ports array
              mode cur_mode
            end
          end
        end
#         mode :read
      end

      # mode :read or :write
      def mode io
#         tag "setting mode to #{io}, (re)intializing @ports array"
        @mode = io
        @ports = @@seq.ports!.values.find_all do |p|
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