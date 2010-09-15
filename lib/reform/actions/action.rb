
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require 'reform/abstractAction'
  require 'forwardable'

  class Action < AbstractAction
    include MenuContext
    extend Forwardable

  private

    def initialize parent, qtc
#       tag "new #{self}, parent = #{parent}"
      super
      connect(@qtc, SIGNAL('triggered()')) do
        unless @qtc.checkable? # because toggled() WILL be called also
          rfRescue do
            if instance_variable_defined?(:@value) && (cid = connector) && (model = effectiveModel)
  #             tag "triggerered. apply_setter #{cid} on model #{model}, connector=#{connector} -> value = #@value"
              model.apply_setter cid, @value
            end
          end
        end
      end
      connect(@qtc, SIGNAL('toggled(bool)')) do |value|
        rfRescue do
          if (cid = connector) && (model = effectiveModel)
            value = @value if value && instance_variable_defined?(:@value)
#             tag "toggled. apply_setter #{cid} on model #{model}, connector=#{connector} -> value = #{value}"
#             tag "stack=#{caller.join("\n")}"
            model.apply_setter(cid, value)
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

        # with a block, set checkable tag and connect the callback. Without a block call the toggled event
    # passing the current value of checked (this works even if no callback was registered).
    # Your callback must accept a single argument.
    def whenToggled &block
      if block
        @qtc.checkable = true
        connect(@qtc, SIGNAL('toggled(bool)'), self) { |checked| rfCallBlockBack(checked, &block) }
      else
        tag "explicit whenToggled call"
        @qtc.toggled(@qtc.checked?)
      end
    end

    def_delegators :@qtc, :enabled=, :enabled?
  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::Action, Action

end