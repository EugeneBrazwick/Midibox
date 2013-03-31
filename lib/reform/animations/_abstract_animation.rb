
require_relative '../control'
module R::Qt

  class AbstractAnimation < Control
    public # methods of AbstractAnimation

      # override
      def setup quickyhash = nil, &block
	super
	#tag "local setup of AbstractAnimation, autostart=#{autostart?}"
	start if autostart?
      end

      #tag "calling 'signal' to create 4 callbacks"

      signal 'currentLoopChanged(int)', 
	     'directionChanged(QAbstractAnimation::Direction',
	     'finished()',
	     'stateChanged(QAbstractAnimation::State, QAbstractAnimation::State)'

      def autostart value
	@autostart = value
      end

      def autostart?
	# if @autostart == nil then consult $app
       	@autostart != false &&
	  (@autostart != nil || $app.autostart_anims?)
      end

      attr_dynamic Fixnum, :loopCount, :currentTime
      attr_dynamic Symbol, :direction
      attr_dynamic FalseClass, :paused

      alias paused? paused_get

      attr_dynamic Fixnum, :duration
  end # class AbstractAnimation

end # module R::Qt
