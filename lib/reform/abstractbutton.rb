
# Copyright (c) 2010-2011 Eugene Brazwick

module Reform

  require_relative 'labeledwidget'

  class AbstractButton < LabeledWidget
    private
      define_simple_setter :text
      alias :title :text

      def transitions trans #= nil #, &block
  #       if trans
          form = containing_form
          trans.each do |transition|
            qtran = form[transition[:from]].qtc.addTransition(@qtc, SIGNAL('clicked()'),
                                                              form[transition[:to]].qtc)
            qtran.addAnimation(form[transition[:animation]].qtc) if transition[:animation]
          end
          nil
  #       else
  #       end
      end

    public

      # with a block associate the block with the 'clicked' signal.
      # Without a block we emit 'clicked'
      def whenClicked paramhash = nil, &block
        if block
          connect(@qtc, SIGNAL('clicked()'), self) { rfCallBlockBack(self, &block) }
        elsif paramhash
          form = containing_form
          paramhash.each do |param, value|
            case param
            when :transition
              value.each do |fromstate, tostate|
                form[fromstate].qtc.addTransition(@qtc, SIGNAL('clicked()'), form[tostate].qtc)
              end
            else
              raise Error, tr("invalid whenClicked parameter '%s'" % param)
            end
          end
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
          if model && model.model_getter?(cid)
            @qtc.text = model.model_apply_getter(cid)
          end
        # ????? if (model = effective_model) && (tcid = text_connector) && model.model_getter?(tcid)
        super
      end

#       def postSetup
#         tag "#{self}::postSetup"
#       end

  end

end # Reform
