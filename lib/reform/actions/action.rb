
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../abstractAction'

  class Action < AbstractAction
    include MenuContext
    private

    def initialize parent, qtc
#       tag "new #{self}, parent = #{parent}"
      super
      connect(@qtc, SIGNAL('triggered()')) do
        rfRescue do
          if instance_variable_defined?(:@value) && (cid = connector) && (model = effectiveModel)
            tag "apply_setter #{cid} on model #{model}, connector=#{connector}"
            model.apply_setter cid, @value
          end
        end
      end
    end

    define_simple_setter :text, :checkable

    alias :label :text
    alias :title :text

    # sets 'enabled' to false
    def disabled
      @qtc.enabled = false
    end

    Sym2Shortcut = { quit: Qt::KeySequence::Quit }

    # it is possible that an Qt::Enum value is passed. pe: Qt::KeySequence::Quit
    # understood symbols: :quit
    def shortcut x
#       tag "setShortcut(#{x.class} #{x})"
      x = Sym2Shortcut[x] if Symbol === x        # first !!
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

    def enabled= value
      @qtc.enabled = value
    end

    def checked?
      @qtc.checked?
    end
  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::Action, Action

end