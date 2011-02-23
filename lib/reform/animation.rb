
#  Copyright (c) 2010 Eugene Brazwick

module Reform
  class Animation < Control
    include AnimationContext

    private

      def initialize parent, qtc
        super
        @autostart = !(Animation === parent)
      end

      def appendTo animid
        containing_form[animid].qtc.addAnimation(@qtc)
      end

      def duration ms
        ms = ms.val if Milliseconds === ms
        @qtc.duration = ms
      end

      # time to set immediately after starting (the very first loop)
      # only works with autostart currently
      def startTime ms
        @startTime = Milliseconds === ms ? ms.val : ms
      end

      def currentTime ms
        @qtc.currentTime = Milliseconds === ms ? ms.val : ms
      end

      define_setter TrueClass, :paused
      define_setter Integer, :direction, :loopCount
      # direction is not really an int so this may fail...

      # previously called 'looping'
      def looping!
        @qtc.loopCount = -1
      end

    protected # Animation methods

      attr_writer :autostart

      def autostart value = nil
        return @autostart unless value
        @autostart = value
      end

      def autostart?
        @autostart
      end

    public # Animation methods

      def looping?
        @qtc.loopCount == -1
      end

      def addTo parent, hash, &block
        parent.addAnimation self, hash, &block
      end

      def addAnimation anim, hash, &block
        super
#         tag "appending #{anim.qtc} to group #@qtc"
        @qtc.addAnimation(anim.qtc)
        anim.autostart = false
      end

      def postSetup
        if @autostart
#           tag "Starting animation"
          @qtc.start
          # it is possible to start the animation in the middle:
          @qtc.currentTime = @startTime if instance_variable_defined?(:@startTime)
        end
      end

      def whenFinished &block
        if block # is a proc actually
          @whenFinished = block
        else
          rfCallBlockBack(&@whenFinished)
        end
      end

      def whenFinished?
        instance_variable_defined?(:@whenFinished)
      end

  end #class Animation

  module QAnimationHackContext
    public
      def finished
#         tag "finished!!"
        rfRescue do
          if @_reform_hack.whenFinished?
            @_reform_hack.whenFinished
          end
        end
      end

#       def stateChanged newState, oldState
#         tag "stateChanged #{newState}, #{oldState}"
#       end

#       def stop
#         super
#         tag "STOP!!!"
#       end

      # Qt::AbstractAnimation::Stopped/Paused/Running
      def updateState newState, oldState
#         tag "updateState #{newState}, #{oldState}"
#         stateChanged newState, oldState # because it does not work properly...
        finished if newState == Qt::AbstractAnimation::Stopped
      end
  end # module QAnimationHackContext

end # module Reform
