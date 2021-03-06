
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require 'reform/layout'
  require_relative 'label'

  class FormLayout < Layout

    # override
    def postSetup
#       tag "#{self}::postSetup"
#       super
      # we must wait until all children are setup.
      children.each do |control|
        # note that labels without a buddy are ignored... (all labels are ignored)
#         tag "Verify #{control}"
=begin
  Labels that have a buddy will be added if the body is added.
=end
        next if control.is_a?(Label) && control.qtc.buddy
        if control.respond_to?(:labeltext) && (label = control.labeltext) # may be a string, may have been converted to a Label reference
          # it could be that the label was already added. And the text set.
          if label.respond_to?(:qtc)
#             tag "add label object + #{control.qtc} '#{control.name}'"
#             orgtext = label.text
#             tag "tekst was '#{orgtext}'"
            @qtc.addRow(label.qtc, control.qtc)
#             label.qtc.text = orgtext # redo ?? NO EFFECT
          else
#             tag "add labeltext #{label} with control #{control.qtc}"
            @qtc.addRow(label, control.qtc)
          end
        else
#           tag "add control #{control.qtc} without a label" # ,caller=#{caller.join("\n")}"
          @qtc.addRow(control.qtc) # no label was ever set.
        end
#         tag "create Label so 'connect' can work"
#         Label.new(self, @qtc.labelForField(control.qtc))
        # NEVER MIND, it can never have a name unless explicit!
      end
#       remove_instance_variable :@collection
#       tag "end postSetup"
    end

    def self.qtimplementor
      Qt::FormLayout
    end

    def addLayout control, hash, &block
      raise 'You cannot add layouts in a formlayout, please use grid, vbox or hbox'
    end
  end # class FormLayout

  createInstantiator File.basename(__FILE__, '.rb'), FormLayout.qtimplementor, FormLayout

end # Reform
