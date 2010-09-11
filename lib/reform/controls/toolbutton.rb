
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'widget'

  class ToolButton < Widget
#     include MenuContext # can create a menu here
    private
#     define_simple_setter :text, :checkable, :flat

      define_simple_setter :iconSize

      def_delegator :@qtc, :icon=

#     def checked value
#       @qtc.checkable = true
#       @qtc.checked = value
#     end

#     def text_connector connector
#       @text_connector = connector
#     end

    public

    # with a block associate the block with the 'clicked' signal.
    # Without a block we emit 'clicked'
    def whenClicked &block
      if block
        connect(@qtc, SIGNAL('clicked()'), self) { rfCallBlockBack(&block) }
      else
        @qtc.clicked
      end
    end #whenClicked

#     def auto_layouthint
#       :hbox
#     end

    #override
#     def updateModel model, options = nil
#       cid = connector and
#         if model && model.getter?(cid)
#           @qtc.text = model.apply_getter(tcid)
#         end
#       super
#     end

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::ToolButton, ToolButton

end # Reform