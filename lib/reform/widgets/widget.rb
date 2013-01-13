
require_relative '../../urqt/liburqt'
require_relative '../control'
require_relative '../context'

module R::Qt
  class Widget < Control
      # you can include any widget inside any other:
      include Reform::WidgetContext

    public # methods of Widget
      # override
      def addWidget widget
	widget.parent = self
      end

      # override
      def addToParent parent
	parent.addWidget self
      end # addToParent

      attr_dynamic String, :title, :caption, :windowTitle
      attr_dynamic Reform::Size, :size

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
    tag "END OF APP"
  } # app
  tag "CLEANED UP OK!"
end  # example/test
