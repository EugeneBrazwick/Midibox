
#  Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../labeledwidget'

  class Edit < LabeledWidget
    private
    define_simple_setter :readOnly, :text, :alignment, :maxLength

    def rightalign
      alignment Qt::AlignRight
    end

    def changed_signal_signature
      'textEdited(const QString &)'
    end

    public
    def connectModel model, options = nil
#       tag "connectModel #{model.inspect}, cid=#{connector}"
      cid = connector or return
      if model && model.getter?(cid)
#         tag "getter located"
        @qtc.text = model.apply_getter(cid)
        init = options && options[:initialize]
        if model.setter?(cid) && init
#           tag "setter located"
          connect(@qtc, SIGNAL(changed_signal_signature), self) do |text|
#             tag "assign '#{text}' to models property #{cid}"
            model.send(cid + '=', text)
          end
        elsif init
          @qtc.readOnly = true
        end
      else
        @qtc.clear
      end
      super
    end
  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::LineEdit, Edit
end # Reform