
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'labeledwidget'

  class AbstractButton < LabeledWidget
    private
    define_simple_setter :text

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
    def updateModel model, options = nil
#       tag "@{self} connectModel #{aModel}, cid=#{connector}"
      cid = connector and
        if model && model.getter?(cid)
          @qtc.text = model.apply_getter(cid)
        end
       # ????? if (model = effective_model) && (tcid = text_connector) && model.getter?(tcid)
      super
    end

  end

end # Reform