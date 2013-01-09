
require_relative '../app' # for Reform::createInstantiator

module R::Qt
  class Widget < Control
    public # methods of Widget
      # override
      def addToParent parent
	parent.addWidget self
      end
  end
end

Reform::createInstantiator __FILE__, R::Qt::Widget

if __FILE__ == $0
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
