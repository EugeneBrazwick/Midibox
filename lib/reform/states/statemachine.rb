
require 'reform/abstractstate'

module Reform
  # yes this is wrong.  But otherwise it fragments too much. And like states it can contain states
  # No it is really not wrong at all! See QStateMachine docu....
  class StateMachine < AbstractState

    private

      def initialize parent, qtc
        super
        @autostart = true
      end

      def autostart val
        @autostart = val
      end

    public

      def postSetup
        if @autostart
#           tag "STARTING STATE MACHINE!!!!!!!!!!!!!!!!!!!!!, initialState = #{@qtc.initialState}, '#{@qtc.initialState && @qtc.initialState.objectName}'"
          @qtc.start
        end
      end
  end

  class QStateMachine < Qt::StateMachine
    include QStateContext
  end

  createInstantiator File.basename(__FILE__, '.rb'), QStateMachine, StateMachine

end