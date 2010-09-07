
# Copyright (c) 2010 Eugene Brazwick

require_relative '../model'

module Reform
  # model class representing the current time.
  # It reconnects to the control each second (by default).
  class TimeModel < Control
    include Model
    private

    def initialize parent, qtc = nil
      super
      @timerid = @timer = nil
      @frequency = 1.0
#       tag "creating timer"
      # OK
      updatetime_ms 1000
    end

    # float. Numbers of cycles that are performed per second
    # This should not be 0.0!!
    def frequency hz
      @frequency = hz
    end

#     Factor = 360.0 / 1_000_000.0

    # by setting another timeout the update signal is sent each value_ms milliseconds
    def updatetime_ms value_ms
#       @updatetime = value_ms
      if @timerid
        killTimer(@timerid)
        # this will also drop the connection
        @timerid = @timer = nil
      end
      @timer = Qt::Timer.new self
      connect @timer, SIGNAL('timeout()') do
        dynamicPropertyChanged :current
      end
      @timerid = @timer.start value_ms
    end

    public

    # angle of the cycle. Assumes it is 0.0 at the 'start' of the timer.
    # The result is always between 0.0 and 360.0
    def angle
      # example, if the freq = 5 hz. we make a full circle every 0.2 s.
      # so 0.2s is 360 degrees. so degrees = 0.2/360s = 1.0/hz/360
      # IN SECONDS???? BUMMER
#       tag "elapsed=#{Qt::Time::currentTime.elapsed}"
#       (Qt::Time::currentTime.elapsed * Factor * @frequency) % 360.0
#       n = Time.now
      (Time.now.to_f * 360.0 * @frequency) % 360.0
#       tag "n=#{n.to_f}, freq=#@frequency -> #{r}"
#       r
    end

    # the current time as a Qt::Time
    def current
      Qt::Time::currentTime
    end
  end

#   tag "calling createInstantiator"
  createInstantiator File.basename(__FILE__, '.rb'), nil, TimeModel

end # module Reform