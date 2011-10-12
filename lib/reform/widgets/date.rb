
#  Copyright (c) 2010-2011 Eugene Brazwick

module Reform

  require_relative 'edit'

  # the gettes and setters should use a QDate.
  class Date < Edit
    private

      # these delegate to Qt::DateEdit
      define_simple_setter :displayFormat, :minimumDate, :maximumDate

      def dateRange from, to
	@qtc.minimumDate, @qtc.maximumDate = from, to
      end

      # override
      def changed_signal_signature
	'dateChanged(const QDate &)'
      end

    public
      #override. Same as Edit except for a single 'text'->'date' conversion.
      def applyModel data
  #       tag "#{self}::updateModel, cid=#{connector}"
	@qtc.date = data || Qt::Date.currentDate
        @qtc.readOnly = @readOnly || !@model.model_setter?(connector)
      end

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::DateEdit, Date
end # Reform
