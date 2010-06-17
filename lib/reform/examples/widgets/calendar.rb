#!/usr/bin/ruby

# Copyright (c) 2010 Eugene Brazwick

require 'reform/app'

# KNOWN ISSUES:  changing current date in 'date' edit does not change the calwidget
# Also, changing locale may switch current year to 7999, even though maxdate is set to 1-1-3000
# below
# Indeed, max date changes in a weird fashion, and daterange for 'date' control
# does not guarantee anything.
# also if mindate is below 0, then the current date changes to negative values, even if
# the positive value is legal.
# It is not really worth the effort to fix this mess right now

class Const < Qt::Object
  MinimumDate = '01-01-1900'
  MaximumDate = '31-12-2999'
  PossibleColors = { Qt::red=>tr('Red'),
                     Qt::blue=>tr('Blue'), Qt::black=>tr('Black'),
                     Qt::magenta=>tr('Magenta') }
end

Reform::app {
  # TODO: Missing are callbacks, but we must see which ones can be done by
  # the model paradigm.
  # follows the window.cpp Nokia example
  form { # use form, not widget, to allow connecting a model
    windowTitle tr('Calendar Widget')
    calendar_model { name :calendarModel }
    gridlayout {  # 'layout'
      fixedsize  # makes the containing widget have a fixed size
      # preview group box  UL
      groupbox { # cosmetic groupbox
        title tr('Preview')
        calendarwidget {
          name :calendarWidget
#           minimumDate Const::MinimumDate   # dd-mm-yy(yy)? or yyyy.mm.dd or mm[^-]dd[^-]yy(yy)?
#           maximumDate Const::MaximumDate   # or dd.MMM.yy(yy)? or MMM.dd.yy(yy)?
#                                     # or yy(yy)?.MMM.dd
                                    # or split in three triple integers y m d
                                    # or int/string triples dMy yMd Mdy as long y > 31
#           gridVisible true
#           whenMonthChanged { } # reformatCalendarPage } # FIXME ??? cannot exist
          makecenter # center it in containerwidget, with a stretchy space around it.
        }
      } # groupbox
      # general options group box  UR
      groupbox { # generalOptionsGroupBox
        layoutpos 1 # by default it goes down, we want to add a column here
        title tr('General Options')
        combobox { # localeCombo
          # use Qt locale languagelist, and for each locale add the
          # countriesForLanguage(lang).
          # the currentlocale must be made the default value and thus function
          # as the 'connecting' modelpart, we should simply set calendar.language_and_country
          name :locale
          locale_model
          labeltext tr('&Locale')  # quicky label association, becomes a 'buddy'
        }
        combobox { # firstDayCombo
          # or datasource({k=>v,...}) or datasource Hash[k=>v,...]
          model CalendarModel::WeekDaysFromSun2Sat
          name :firstDayOfWeek # should return a Qt::XXXday
        }
        # as demo, I write it in full, but could place 'label' in combobox here as well
        label { # firstDayLabel
          text tr('Wee&k starts on:')
          buddy :firstDayOfWeek
        }
        combobox { # selectionModeCombo
          model CalendarWidget::PossibleSelections
          labeltext tr('&Selection mode:')
        }
         hbox { # checkBoxLayout
          checkbox { # gridCheckBox
            text tr('&Grid')
            name :gridVisible?
          }
          spacer stretch: 1 # stretchable open space in between
          checkbox { # navigationCheckBox
            text tr('&Navigation Bar')
            name :navigationBarVisible?
          }
        } # hbox
        combobox {# horizontalHeaderCombo
          name :horizontalHeaderFormat
          model CalendarWidget::PossibleHorizontalHeaderOptions
#           currentIndex 1  # this alters the model on initialization, even!!
          labeltext tr('&Horizontal header:')
        }
        combobox { # verticalHeaderCombo
          name :verticalHeaderFormat
          model CalendarWidget::PossibleVerticalHeaderOptions
          labeltext tr('&Vertical header:')
        }
      } # generalOptionsGroupBox

      # dates group box  BL
      groupbox { # datesGroupBox
        title tr('Dates')
        date { # minimumDateEdit
          displayFormat 'MMM d yyyy'
          dateRange Const::MinimumDate, Const::MaximumDate
          name :minimumDate
          labeltext tr('&Minimum Date:')
        }
        date { # currentDateEdit
          displayFormat 'MMM d yyyy'
          dateRange Const::MinimumDate, Const::MaximumDate
          name :selectedDate
          labeltext tr('&Current Date:')
        }
        date { # maximumDateEdit
          displayFormat 'MMM d yyyy'
          dateRange Const::MinimumDate, Const::MaximumDate
          name :maximumDate
          labeltext tr('Ma&ximum Date:')
        }
      } # dateGroupBox
      # textformats group box  BR
      groupbox { # TextFormatsGroupBox
        title tr('Text Formats')
        calendarcolorcombo { # contrib widget
                             # it should be possible to make such a thing
                             # within the application here.
=begin
add_controlclass :calendarcolorcombo do
  combobox {
    datasource PossibleColors
 }
end
It is rather contrived. How can we easily add such a template to the PanelContext?
add_graphicclass
add_formclass
add_menuitemclass
However they play dirty since it is really a canned command being executed in the
proper context. Maybe we should call it a 'macro'.
We 'can' a 'control' so 'can_control'.  But it looks like a question...
=end
          currentKey Qt::black
          labeltext tr('&Weekday color:')
          whenActivated do |data, idx|
            format = Qt::TextCharFormat.new
            format.foreground = Qt::Brush.new(data) # .to_color
            calendarWidget.setWeekdayTextFormat(Qt::Monday, format);
            calendarWidget.setWeekdayTextFormat(Qt::Tuesday, format);
            calendarWidget.setWeekdayTextFormat(Qt::Wednesday, format);
            calendarWidget.setWeekdayTextFormat(Qt::Thursday, format);
            calendarWidget.setWeekdayTextFormat(Qt::Friday, format);
          end
        }
        combobox { # weekendColorCombo
          model Const::PossibleColors
          currentKey Qt::red
          labeltext tr('Week&end color:')
          whenActivated do |data, idx|
            (format = Qt::TextCharFormat.new).foreground = Qt::Brush.new(data)
            calendarWidget.setWeekdayTextFormat Qt::Saturday, format
            calendarWidget.setWeekdayTextFormat Qt::Sunday, format
          end
        }
        combobox {
          model tr('Bold'), tr('Italic'), tr('Green'), tr('Plain')
          labeltext tr('&Header text:')
          whenActivated do |data, idx|
            format = Qt::TextCharFormat.new
            case idx
            when 0 then format.fontWeight = Qt::Font::Bold
            when 1 then format.fontItalic = true
            when 2 then format.foreground = Qt::Brush.new(Qt::green)
            end
            calendarWidget.headerTextFormat format
          end
        }
=begin
these two are problematic.
Since they are NOT part of Qt::CalendarWidget it seems ugly to still
add an implementation.
solution 1) extend both model + widget with subclasses, maybe even in this form.
solution 2) just ad hoc code it, similar to the example
=end
        hbox { # checkBoxLayout
          checkbox {
            name :firstFridayCheckbox
            connector false
            text tr('&First Friday in blue')
            whenClicked { |checked| updateModel(@model) }
          }
          spacer stretch: 1
          checkbox {
            name :mayFirstCheckbox
            connector false
            text tr('May &1 in red')
            whenClicked do |checked|
#               tag "whenClicked, self=#{self}, calling whenCon"
              updateModel(@model)
            end
          }
        } # hbox
      } # textFormatsGroupBox
    }  # layout
#     tag "setting whenConnected form callback"
       # FIXME: once set, this is never unset and I cannot find how the original
       # example does this.
    whenConnected do |model|
      if firstFridayCheckbox.checked?
        firstFriday = Qt::Date.new(calendarWidget.yearShown, calendarWidget.monthShown, 1)
        firstFriday = firstFriday.addDays(1) while firstFriday.dayOfWeek != Qt::Friday
        firstFridayFormat = Qt::TextCharFormat.new
        firstFridayFormat.foreground = Qt::Brush.new(Qt::blue)
        calendarWidget.setDateTextFormat(firstFriday, firstFridayFormat)
      end
      #May First in Red takes precedence, so we do that later
      if mayFirstCheckbox.checked?
        mayFirst = Qt::Date.new(calendarWidget.yearShown, 5, 1)
        mayFirstFormat = Qt::TextCharFormat.new
        mayFirstFormat.foreground = Qt::Brush.new(Qt::red)
        calendarWidget.setDateTextFormat(mayFirst, mayFirstFormat)
      end
    end
  } # form
} # app