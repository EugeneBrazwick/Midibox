
#  Copyright (c) 2013 Eugene Brazwick

require_relative '../context'
require_relative '../layoutable'

module R::Qt
  class Widget < Control
      # you can include any widget inside any other:
      include Reform::WidgetContext, Reform::ModelContext
      include Layout::Able

    public # methods of Widget

      # override
      def parent_get
	#tag "#{self}::parent_get, @parent=#{@parent}" 
	# the iv always overrides
	@parent || qtparent_get
      end # parent_get

      # override
      def addWidget widget
	widget.qtparent = self
      end # addWidget

      # override
      def addLayout layout
	raise Reform::Error, "a widget can only have one layout" if self.layout
	self.layout = layout
      end # addLayout

      # override
      def parent= parent 
	parent.addWidget self
      end # parent=

      attr_dynamic String, :title
      attr_dynamic Reform::Size, :size

      alias caption title
      alias windowTitle title

      #override
      def connect_attribute methodname, dynattr
	case methodname
	  # this is just the list of attr_dynamics?
	  # No there may be aliases too.
	when :title, :caption, :windowTitle, 
	     :size
	else
	  super
	end
      end
  end # class Widget

  # req. for a plugin:
  Reform.createInstantiator __FILE__, Widget

end # module R_Qt

if __FILE__ == $0
  require_relative '../app' # for Reform::createInstantiator
  Reform.app {
    widget {
      size 320, 240
      title 'Top-level widget'
      shown { $app.quit }
      # the idea is that you can say this too: 
      #	    shown(send_to: $app) { quit }
    } # widget
    $stderr.puts "END OF APP"
  } # app
  $stderr.puts "CLEANED UP OK!"
end  # example/test
