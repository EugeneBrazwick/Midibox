
#  Copyright (c) 2010-2011 Eugene Brazwick

module Reform

  require_relative 'edit'

  # the gettes and setters should use a QDate.
  class Date < Edit
    private

    define_simple_setter :displayFormat, :minimumDate, :maximumDate

    def dateRange from, to
      @qtc.minimumDate = from
      @qtc.maximumDate = to
    end

    # override
    def changed_signal_signature
      'dateChanged(const QDate &)'
    end

    public
    #override. Same as Edit except for a single 'text'->'date' conversion.
    def updateModel model, options = nil
#       tag "#{self}::updateModel, cid=#{connector}"
      cid = connector and
        if model && model.model_getter?(cid)
  #         tag "model_apply getter -> #{model.model_apply_getter(cid)}"
          @qtc.date = model.model_apply_getter(cid) || Qt::Date.currentDate
  #         tag "Qt::Date.new == #{Qt::Date.new} == today?? NO"
  #         tag "Date #{name}, date := #{@qtc.date.inspect}"
          @qtc.readOnly = !model.model_setter?(cid)
        else
  #         tag "clear #{name}"
  #         @qtc.date = nil  SEGV
          @qtc.date = Qt::Date.currentDate
        end
      super
    end

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::DateEdit, Date
end # Reform