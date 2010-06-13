
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../abstractAction'

  class Action < AbstractAction
    include MenuContext
    private

    def initialize parent, qtc
      super
      connect(@qtc, SIGNAL('triggered()')) do
        rfRescue do
          if instance_variable_defined?(:@value) && cid = connector && model = effectiveModel
            model.apply_setter cid, @value
          end
        end
      end
    end

    define_simple_setter :text, :checkable

    alias :label :text
    #, :shortcut

    # it is possible that an Qt::Enum value is passed. pe: Qt::KeySequence::Quit
    def shortcut x
#       tag "setShortcut(#{x.class} #{x})"
      x = Qt::KeySequence.new(x) if x.is_a?(Qt::Enum)
      @qtc.shortcut = x
    end

    def checked v
      @qtc.checkable = true
      @qtc.checked = v
    end

    def value v = nil
      return instance_variable_defined(:@value) && @value unless v
      @value = v
    end

    public
    def checked?
      @qtc.checked?
    end
  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::Action, Action

end