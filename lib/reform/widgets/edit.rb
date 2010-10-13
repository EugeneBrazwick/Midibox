
#  Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../labeledwidget'

  class Edit < LabeledWidget
    private

      def initialize parent, qtc
        super
        @mem_text = nil
#         tag "new Edit(parent=#{parent}, qtc=#{qtc})"
        connect(@qtc, SIGNAL('editingFinished()'), self) do
          unless @qtc.readOnly?  # Qt manages to send editingFinished even if the control is readonly...
            if @mem_text != @qtc.text && model && (cid = connector) #&& model.setter?(cid)
              rfRescue do
#                 tag "EditingFinished, assign '#{@qtc.text}' to models property cid=#{connector}, @model=#{@model}"
                model.apply_setter(cid, @mem_text = @qtc.text, self)
              end
            end
          end
        end
  #       tag "initialized edit"
      end

      define_simple_setter :readOnly, :text, :alignment, :maxLength

      def rightalign
        alignment Qt::AlignRight
      end

      def changed_signal_signature
        'textEdited(const QString &)'
      end

      def applyModel data
#         tag "applyModel, data = #{data}"
        @mem_text = @qtc.text = data.respond_to?(:to_str) ? data.to_str : data.to_s
        @qtc.readOnly = !@model.setter?(connector)
      end

    public

    def insert(*args)
      @qtc.insert(*args)
    end

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::LineEdit, Edit
end # Reform