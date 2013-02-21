
# Copyright (c) 2010-2013 Eugene Brazwick

require_relative '../model'
require_relative '../context'

module R::Qt
  # A class representing the current time.
  # Available as      
  #	connector  :now
  # Similar you can do this:
  #	connector  :now, :sec
  #	connector  :now, :min
  #	connector  :now, :hour
  #	connector  :now, :to_s
  class Timer < Model
    private # methods of TimeModel
      def initialize *args
        super
	@autostart = true
	# cycle_frequency is the number of 360 degree cycles per second.
	# Used by angle.
        @cycle_frequency = 1.0
	@frame_nr = 0
	#tag "tracing prop"; trace_propagation true
	timeout do
	  @frame_nr += 1
	  #tag "And now we propagate the lot"
	  [:frame_nr, :now, :angle, :hour12_f, :hour_f, :min_f].each do |comp|
	    model_propagate comp, self
	  end
	end
	interval 100
      end # initialize

    public # methods of TimeModel

      alias singleShot_get singleShot?

      attr_dynamic TrueClass, :autostart, attr_accessor: true
      attr_dynamic FalseClass, :singleShot, attr_accessor: true
      attr_dynamic Float, :cycle_frequency, attr_accessor: true 
      # interval is QTimer.interval
      attr_dynamic Fixnum, :interval
      attr_dynamic Symbol, :timeType

      alias single_shot singleShot
      alias one_shot singleShot
      alias oneShot singleShot
      alias interval_ms interval

      class << self
	alias single_shot singleShot
	alias one_shot singleShot
	alias oneShot singleShot
      end

      attr :frame_nr

      def now
	Time.now
      end

      def setup *args
	super
	start if @autostart
      end

      def angle
	tag "angle, now=#{now.inspect}, now.to_f=#{now.to_f}"
	(now.to_f * 360.0 * @cycle_frequency) % 360.0
      end

      def hour_f
        n = now
        n.hour + n.min / 60.0 + n.sec / 3600.0
      end

      def hour12_f
        n = now
        n.hour % 12 + n.min / 60.0 + n.sec / 3600.0
      end

      def min_f
        n = now
        n.min + n.sec / 60.0
      end
  
      def method_missing sym, *args
	#tag "Qt::Timer.method_missing(:#{sym}, #{args.inspect})"
	now.send sym, *args
      end

      signal 'timeout()'

  end # class Timer

  Reform.createInstantiator __FILE__, Timer
end # module R::Qt

