
# Copyright (c) 2010 Eugene Brazwick
module Reform

  require 'reform/widget'

=begin
  very specific kind of widget, that can be used as a small (1 row high) labeled
  control in a form class.

  If added to a formlayout, the label is created next to it.
  If added to a gridlayout, if in column 0, the label is put in column 1.
  But if added in column > 0 then the label is stored in column in front of it with right alignment.
=end
  class LabeledWidget < Widget

    module Implementation
      # when added to a parent, some measures should be taken, but in some cases
      # the parent will handle it, like formlayout.addWidget
      # currently this only works ok when using a formlayout!!
      # NOTE: label is BANNED from being used as a function, since it already is an instantiator!!
      def labeltext value = nil
        return (instance_variable_defined?(:@label) ? @label : nil) unless value
        @label = value
      end

      def auto_layouthint
  #       tag "auto_layouthint -> :formlayout"
        :formlayout
      end
    end

    include Implementation
  end
end
