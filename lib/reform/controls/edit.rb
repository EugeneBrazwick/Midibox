
#  Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../labeledwidget'

  class Edit < LabeledWidget
    private

    def initialize parent, qtc
      super
      connect(@qtc, SIGNAL(changed_signal_signature), self) do |txt|
#             tag "assign '#{text}' to models property #{cid}"
        model = effectiveModel and cid = connector and model.apply_setter(cid, txt)
      end
    end

    define_simple_setter :readOnly, :text, :alignment, :maxLength

    def rightalign
      alignment Qt::AlignRight
    end

    def changed_signal_signature
      'textEdited(const QString &)'
    end

    public

    def insert(*args)
      @qtc.insert(*args)
    end

    def connectModel model, options = nil
#       tag "connectModel #{model.inspect}, cid=#{connector}"
      cid = connector or return
      if model && model.getter?(cid)
#         tag "getter located"
        @qtc.text = model.apply_getter(cid)
        @qtc.readOnly = !model.setter?(cid)
      else
        @qtc.clear
      end
      super
    end

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::LineEdit, Edit
end # Reform