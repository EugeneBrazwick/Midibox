
# Copyright (c) 2010 Eugene Brazwick
module Reform
  require_relative 'widget'

  # very specific kind of widget, that can be used as a small (1 row high) labeled
  # control in a form class.
  class LabeledWidget < Widget

    public
    # when added to a parent, some measures should be taken, but in some cases
    # the parent will handle it, like formlayout.addWidget
    # currently this only works ok when using a formlayout!!
    # NOTE: label is BANNED from being used a string, since it already is an instantiator!!
    def labeltext value = nil
      return (instance_variable_defined?(:@label) ? @label : nil) unless value
      @label = value
    end
  end
end
