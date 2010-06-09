
# Copyright (c) 2010 Eugene Brazwick

require_relative '../model'

module Reform
  # model class representing the current time.
  # It reconnects to the control each second (by default).
  class TimeModel < Qt::Object
    include Model
    private

    def initialize
      super # !!!!!
      @timerid = @timer = nil
#       tag "creating timer"
      # OK
      updatetime_ms 1000
    end

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

    def current
      Qt::Time::currentTime
    end
  end

#   tag "calling createInstantiator"
  createInstantiator File.basename(__FILE__, '.rb'), nil, TimeModel

end # module Reform