
#  Copyright (c) 2010-2011 Eugene Brazwick

module Reform

  require_relative '../labeledwidget'

  class Edit < LabeledWidget
    private

      def initialize parent, qtc
        super
        @mem_text = nil
	@readOnly = false
#         tag "new Edit(parent=#{parent}, qtc=#{qtc})"
        connect(@qtc, SIGNAL('editingFinished()'), self) do
          unless @qtc.readOnly?  # Qt manages to send editingFinished even if the control is readonly...
           rfRescue do
              if @mem_text != @qtc.text && (mod = model) && (cid = connector) #&& model.model_setter?(cid)
#                 tag "EditingFinished, assign '#{@qtc.text}' to models property cid=#{connector}, @model=#{@model}"
                mod.model_apply_setter(cid, @mem_text = @qtc.text, self)
              end
            end
          end
        end
  #       tag "initialized edit"
      end

      define_simple_setter :text, :alignment, :maxLength

      define_setter FalseClass, :readOnly, shadowed: true

      def rightalign
        alignment Qt::AlignRight
      end

      def changed_signal_signature
        'textEdited(const QString &)'
      end

      def applyModel data
#        tag "applyModel, data = #{data.inspect}"
        @mem_text = @qtc.text = data.respond_to?(:to_str) ? data.to_str : data.to_s
        @qtc.readOnly = @readOnly || !@model.model_setter?(connector)
      end

    public

      def insert(*args)
	@qtc.insert(*args)
      end

      attr_writer :readOnly # as shadow of qtc.readOnly
  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::LineEdit, Edit
end # Reform
