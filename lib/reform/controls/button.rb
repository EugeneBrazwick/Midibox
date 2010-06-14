
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'widget'

  class Button < Widget
    include MenuContext # can create a menu here
    private
    define_simple_setter :text, :checkable, :flat

    def checked value
      @qtc.checkable = true
      @qtc.checked = value
    end

    def text_connector connector
      @text_connector = connector
    end

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

    def auto_layouthint
      :hbox
    end

    #override
    def addControl control, quickyhash = nil, &block
      raise 'DEPRECATED'
#       raise unless control.menu?
      @qtc.setMenu(control.qtc)
      super
    end

    def connectModel aModel, options = nil
#       tag "@{self} connectModel #{aModel}, cid=#{connector}"
      @qtc.text = model.apply_getter(tcid) if (model = effective_model) && (tcid = text_connector) && model.getter?(tcid)
      super
    end

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::PushButton, Button

end # Reform