
#  Copyright (c) 2010 Eugene Brazwick

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
    def connectModel model, options = nil
#       tag "#{self}::connectModel, cid=#{connector}"
      cid = connector or return
      if model && model.getter?(cid)
#         tag "apply getter -> #{model.apply_getter(cid)}"
        @qtc.date = model.apply_getter(cid) || Qt::Date.currentDate
#         tag "Qt::Date.new == #{Qt::Date.new} == today?? NO"
#         tag "Date #{name}, date := #{@qtc.date.inspect}"
        init = options && options[:initialize]
        if model.setter?(cid) && init
          connect(@qtc, SIGNAL(changed_signal_signature), self) do |dat|
            model.send(cid + '=', dat)
          end
        elsif init
          @qtc.readOnly = true
        end
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