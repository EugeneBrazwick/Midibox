
#  Copyright (c) 2013 Eugene Brazwick

require_relative '../context'
require_relative '_layoutable'
require 'forwardable'

module R::Qt
  class Widget < Control
      extend Forwardable
      # you can include any widget inside any other:
      include Reform::WidgetContext, Reform::ModelContext
      include Layout::Able

    private #methods of Widget

      def create_infused_layout
	require_relative 'vboxlayout'
	vboxlayout
	layout or Reform::Error.raise 'broken auto-vboxlayout'
      end

      def infused_layout!
	layout || create_infused_layout
      end

    public # methods of Widget

      # override
      def parent_get
	#tag "#{self}::parent_get, @parent=#{@parent}" 
	# the iv always overrides
	@parent || qtparent_get
      end # parent_get

      def_delegators :infused_layout!, :addWidget

      # override
      def addLayout aLayout
	layout and layout.addLayout aLayout or self.layout = aLayout
      end # addLayout

      # override
      def parent= parent 
	parent.addWidget self
      end # parent=

      def font *args, &block
	#tag "font(#{args.inspect})"
	require_relative '../font'
	return font_get unless args[0] || block
	Font.new self, *args, &block
      end

      #tag "setting up 'title' attr_dynamic"
      attr_dynamic String, :title
      attr_dynamic Size, :size, :minimumSize, :maximumSize
      attr_dynamic Margins, :contentsMargins

      alias caption title
      alias windowTitle title

    #tag "Scanned class Widget OK"
  end # class Widget

  class SynthWidget < Widget
    def synthesized?; true; end
  end

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
