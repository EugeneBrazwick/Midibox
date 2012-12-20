module Reform
  class AbstractState < Control
    include StateContext

    private

      def initialize parent, qtc
        super
        @qtc.instance_variable_set :@_reform_hack, self
#         tag "new AbstractState, qtc = #{qtc}, hacked=#{qtc && qtc.instance_variable_defined?(:@_reform_hack)}"
#         @got_states = false
      end

      def states *ids
        ids.each do |id|
#           tag "Creating Qt::State.new(#@qtc)"
          qstat = QState.new(@qtc)
          state = AbstractState.new(self, qstat)
          state.name id
#           raise 'DAMN' unless state.name.to_s == qstat.objectName
#           tag "state.name = #{state.name}"
          unless @qtc.initialState
#             tag "Setting #{@qtc}/#{@qtc.objectName}.initialState to #{qstat}/#{qstat.objectName}"
            @qtc.initialState = qstat
          end
         end
      end

    public

      # override
      def addState state, quickyhash = nil, &block
#         tag "addState"
#         @qtc.addState state.qtc # No need. Even wrong
        super
#         unless @got_states
#           @got_states = true
        unless @qtc.initialState
#           tag "Setting #{@qtc}.initialState to #{state.qtc}/#{state.name}"
          @qtc.initialState = state.qtc
        end
#         end
      end

      def addTo parent, hash, &block
        parent.addState self, hash, &block
      end

      def whenEntered event = nil, &block
        if block # is a proc actually
          @whenEntered = block
        else
          rfCallBlockBack(event, &@whenEntered)
        end
      end #whenEntered

      def whenEntered?
        instance_variable_defined?(:@whenEntered)
      end

      def whenExited event = nil, &block
        if block # is a proc actually
          @whenExited = block
        else
          rfCallBlockBack(event, &@whenExited)
        end
      end #whenExited

      def whenExited?
        instance_variable_defined?(:@whenExited)
      end

  end # class AbstractState

  module QStateContext

      #override
      def onEntry event
#         tag "#{self}/#{objectName}.onEntry, hacked=#{instance_variable_defined?(:@_reform_hack)}"
        if instance_variable_defined?(:@_reform_hack) && @_reform_hack.whenEntered?
          @_reform_hack.whenEntered(event)
        end
        super
      end

      #override
      def onExit event
#         tag "#{self}/#{objectName}.onExit"
        if instance_variable_defined?(:@_reform_hack) && @_reform_hack.whenExited?
          @_reform_hack.whenExited(event)
        end
        super
      end
  end

  # make sure whenEntered is going to work
  class QState < Qt::State
    include QStateContext
  end

end # module Reform
