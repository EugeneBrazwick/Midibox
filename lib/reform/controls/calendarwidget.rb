#!/usr/bin/ruby -w

# Copyright (c) 2010 Eugene Brazwick

require 'Qt'

require_relative '../app'

module Reform

  require_relative '../widget'
  require_relative '../models/calendar_model'

  class CalendarWidget < Widget
    private

    def initialize parent, qtc
      super
      connect(@qtc, SIGNAL('selectionChanged()'), self) do
#            tag "SELCHANGE, date #{@qtc.selectedDate.inspect}"
          # BEWARE FOR LOOP/STACKOVERFLOW. this will call updateModel
          # which calls @qtc.selectedDate := X
          # which MAY trigger selectionChanged(). However, it doesn't seem to do that
          # to be safe I use options[:property]
        rfRescue { model = effectiveModel and model.selectedDate = @qtc.selectedDate }
      end
    end

    def minimumDate *value
#       tag "#{self}::minimumDate, qtc=#@qtc"
      return @qtc.minimumDate if value.empty?
      @qtc.minimumDate = CalendarModel::to_date(*value)
    end

    def maximumDate *value
      return @qtc.maximumDate if value.empty?
      @qtc.maximumDate = CalendarModel::to_date(*value)
    end

    define_simple_setter :gridVisible

    def whenCurrentPageChanged &block
      if block
        connect(@qtc, SIGNAL('currentPageChanged(int, int)'), self) do

          rfCallBlockBack(&block)
        end
      else
        @qtc.currentPageChanged(@qtc.yearShown, @qtc.monthShown)
      end
    end

    alias :whenMonthChanged :whenCurrentPageChanged

    PossibleSelections = { Qt::CalendarWidget::SingleSelection=>tr("Single selection"), # DEFAULT
                           Qt::CalendarWidget::NoSelection=>tr("None") }

    PossibleHorizontalHeaderOptions = {
      Qt::CalendarWidget::SingleLetterDayNames=>tr('Single letter day names'),
      Qt::CalendarWidget::ShortDayNames=>tr('Short day names'), # DEFAULT
      Qt::CalendarWidget::NoHorizontalHeader=>tr('None')
    }

    PossibleVerticalHeaderOptions = {
      Qt::CalendarWidget::ISOWeekNumbers=>tr('ISO week numbers'),  # DEFAULT
      Qt::CalendarWidget::NoVerticalHeader=>tr('None') }

    public
    #override
    @@connectingModelSem = false

    def updateModel model, options = nil
      return if @@connectingModelSem
      @@connectingModelSem = true
#       tag "#{self}::updateModel, qtc=#@qtc, caller=#{caller.join("\n")}, options=#{options.inspect}"
#       with model do
        # this is crude code. It simply assumes that model is the right one.
      #it also assumes model is not nil
      # RESSETTING all dateformatting first, to erase specific hacks in the
      # calendar example.
      @qtc.setDateTextFormat(Qt::Date.new, Qt::TextCharFormat.new)
      @qtc.minimumDate = model.minimumDate
      @qtc.maximumDate = model.maximumDate
      @qtc.selectionMode = model.selectionMode
      @qtc.horizontalHeaderFormat = model.horizontalHeaderFormat
      @qtc.verticalHeaderFormat = model.verticalHeaderFormat
      @qtc.navigationBarVisible = model.navigationBarVisible?
      @qtc.gridVisible = model.gridVisible?
      @qtc.firstDayOfWeek = model.firstDayOfWeek
      unless options && options[:property] == :selectedDate
        @qtc.selectedDate = model.selectedDate || Qt::Date.new
      end
      lang = model.locale || 'C'
#       tag "lang := #{lang}"
      @qtc.locale = Qt::Locale.new(lang)
      super
    ensure
      @@connectingModelSem = false
    end

    def setWeekdayTextFormat *args
      @qtc.setWeekdayTextFormat(*args)
    end

    def setDateTextFormat *args
      @qtc.setDateTextFormat(*args)
    end

    define_simple_setter :headerTextFormat

    def yearShown
      @qtc.yearShown
    end

    def monthShown
      @qtc.monthShown
    end

  end # CalendarWidget

  QCalendarWidget = Qt::CalendarWidget

  createInstantiator File.basename(__FILE__, '.rb'), QCalendarWidget, CalendarWidget

end

__END__
if __FILE__ == $0
  include Reform
  p CalendarWidget::to_date('31-12-2093')
#   Qt::Date.new(CalendarWidget::to_date('31-12-2093'))  Time -> Date -> crack
  p CalendarWidget::to_date('13-11-93')  # 1993 !!!
  p CalendarWidget::to_date('12/31/2093')
  p CalendarWidget::to_date('12/14/93')  # 1993 !!!
  p CalendarWidget::to_date('Jan 14 93')  # 1993 !!!
  p CalendarWidget::to_date('4 Jan 2011')
  p CalendarWidget::to_date('2011 January 3')
  p CalendarWidget::to_date('2011/1/31')
  p CalendarWidget::to_date(2, 1, 31)
  p CalendarWidget::to_date(25, 'Feb', 2010)
  p CalendarWidget::to_date(2219, 'Feb', 10)
  p CalendarWidget::to_date('March', 28, 2010)
end
