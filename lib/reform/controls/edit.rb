
#  Copyright (c) 2010 Eugene Brazwick

module Reform

  class Edit < Widget
    private
    define_simple_setter :readOnly, :text, :alignment, :maxLength

    def rightalign
      alignment Qt::AlignRight
    end

    public
    def connectModel model, options = nil
#       tag "connectModel #{model.inspect}, cid=#{connect_id}"
      cid = connect_id or return
      if model && model.getter?(cid)
#         tag "getter located"
        @qtc.text = model.send(cid)
        if model.setter?(cid)
#           tag "setter located"
          connect(@qtc, SIGNAL('textEdited(const QString &)'), self) do |text|
#             tag "assign '#{text}' to models property #{cid}"
            model.send(cid + '=', text)
          end
        elsif options && options[:initialize]
          @qtc.readOnly = true
        end
      else
        @qtc.clear
      end
    end
  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::LineEdit, Edit
end # Reform