
# Copyright (c) 2010-2011 Eugene Brazwick

require 'reform/model'

module Reform
  # model class representing the current time.
  # It reconnects to the control each second (by default).
  class TimeModel < AbstractModel
    private

      def initialize parent, qtc = nil
        super
#         tag "TimeModel.new(#{parent}, #{qtc})"
#         @timerid = nil
        @autostart = true

#         @current = Qt::Time::currentTime # this may lag!! FIXME? can we not always return the currentTime??
# BAD IDEA:  @current != current

        @frequency, @frameNr, @oneShot = 1.0, 0, false
        connect @qtc, SIGNAL('timeout()') do
#           tag "TIMEOUT"
          transaction do |tran|
            self.frameNr += 1
#             tag "self.current := .... "
            self.current = Qt::Time::currentTime
            tran.addDependencyChange :to_s
            tran.addDependencyChange :toString
          end
        end
  #       tag "creating timer"
        # OK
        @qtc.interval = 1000
      end

      def autostart val
        @autostart = val
      end

# float. Numbers of cycles that are performed per second
      # This should not be 0.0!! Currently only used by 'angle'
      # this got nothing to do with the interval of the timer!
      def frequency hz
        @frequency = hz
      end

  #     Factor = 360.0 / 1_000_000.0

      # by setting another timeout the update signal is sent each value_ms milliseconds
      def updatetime_ms value_ms
        value_ms = value_ms.val if Milliseconds === value_ms
        @qtc.interval = value_ms
  #       @updatetime = value_ms
      end

      alias :updatetime :updatetime_ms
      alias :interval :updatetime_ms

      define_simple_setter :singleShot

      alias :oneShot :singleShot # read too much manga!

    public

      def postSetup
#         tag "postSetup, autostart = #@autostart"
        @qtc.start if @autostart
      end

      def toString format = Qt::TextDate
        return (current || Qt::Time::currentTime).toString(format)
      end

      alias :to_s :toString

      # angle of the cycle. Assumes it is 0.0 at the 'start' of the timer.
      # The result is always between 0.0 and 360.0
      def angle frequency = nil
        # example, if the freq = 5 hz. we make a full circle every 0.2 s.
        # so 0.2s is 360 degrees. so degrees = 0.2/360s = 1.0/hz/360
        # IN SECONDS???? BUMMER
  #       tag "elapsed=#{Qt::Time::currentTime.elapsed}"
  #       (Qt::Time::currentTime.elapsed * Factor * @frequency) % 360.0
  #       n = Time.now
        frequency ||= @frequency
        (Time.now.to_f * 360.0 * frequency) % 360.0
  #       tag "n=#{n.to_f}, freq=#@frequency -> #{r}"
  #       r
      end

      def hour_f
        n = Time.now
        n.hour + n.min / 60.0 + n.sec / 3600.0
      end

      def hour12_f
        n = Time.now
        n.hour % 12 + n.min / 60.0 + n.sec / 3600.0
      end

      def min_f
        n = Time.now
        n.min + n.sec / 60.0
      end

      def hour
        Time.now.hour
      end

      def min
        Time.now.min
      end

      def sec
        Time.now.sec
      end

      model_dynamic_accessor :frameNr, :current

      def start
        @qtc.start
      end
  end

#   tag "calling createInstantiator"
  createInstantiator File.basename(__FILE__, '.rb'), Qt::Timer, TimeModel

end # module Reform