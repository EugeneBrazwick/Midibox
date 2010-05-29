
#  Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'layout'

  class Spacer < Widget
  end
  
  class BoxLayout < Layout
    def addWidget control, qt_widget = nil
      (@collection ||= []) << control
      # we must delay until we are sure the children are setup
    end

    # override
    def postSetup
      # now all controls are setup, add them to the layout with the proper 'stretch'
      for control in (@collection ||= [])
	case control
	when Layout then @qtc.addLayout(control.qtc, control.stretch || 0)
	when Spacer
	  if (spacing = control.spacing) && spacing > 0
	    @qtc.addSpacing(spacing)
	  else
	    @qtc.addStretch(control.stretch)
	  end
        else
# 	  tag "#@qtc::addWidget(#{control.qtc}, stretch=#{control.stretch})"
	  @qtc.addWidget(control.qtc, control.stretch || 0)
        end
      end
      remove_instance_variable :@collection
    end
  end # class BoxLayout
end