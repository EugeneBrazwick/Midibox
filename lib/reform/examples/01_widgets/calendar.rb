#!/usr/bin/ruby

# Copyright (c) 2010-2011 Eugene Brazwick

require 'reform/app'

# KNOWN ISSUES:  
# changing locale may switch current year to 7999, even though maxdate is set to 1-1-3000
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
	  # we connect to the calendar model, 'as is'
	  connector :self
        }
      } # groupbox
      # general options group box  UR
      groupbox { # generalOptionsGroupBox
        layoutpos 1 # by default it goes down, we want to add a column here
        title tr('General Options')
	vbox {
	  formlayout {
	    combobox { # localeCombo
	      # use Qt locale languagelist, and for each locale add the
	      # countriesForLanguage(lang).
	      # the currentlocale must be made the default value and thus function
	      locale_model
	      connector :locale
	      labeltext tr('&Locale')  # quicky label association, becomes a 'buddy'
	    }
	    combobox { # firstDayCombo
	      model_connector [:model_root, :weekdays]
	      name :firstDayOfWeek  # 'needed' for buddy
	      connector :firstDayOfWeek 
	    }
	    # as demo, I write it in full, but could place 'label' in combobox here as well
	    label { # firstDayLabel
	      text tr('Wee&k starts on:')
	      buddy :firstDayOfWeek
	    }
	    combobox { # selectionModeCombo
	      # I could have said: model_connector [:model_root, :possibleSelections]
	      struct Reform::CalendarModel::PossibleSelections
	      labeltext tr('&Selection mode:')
	      connector :selectionMode
	    }
	  }
	  hbox { # checkBoxLayout
	    checkbox { # gridCheckBox
	      text tr('&Grid')
	      connector :gridVisible?
	    }
	    spacer stretch: 1 # stretchable open space in between
	    checkbox { # navigationCheckBox
	      text tr('&Navigation Bar')
	      connector :navigationBarVisible?
	    }
	  } # hbox
	  formlayout {
	    combobox {# horizontalHeaderCombo
	      struct Reform::CalendarModel::PossibleHorizontalHeaderOptions
	      connector :horizontalHeaderFormat
    #           currentIndex 1  # this alters the model on initialization, even!!
	      labeltext tr('&Horizontal header:')
	    }
	    combobox { # verticalHeaderCombo
	      struct Reform::CalendarModel::PossibleVerticalHeaderOptions
	      connector :verticalHeaderFormat
	      labeltext tr('&Vertical header:')
	    }
	  } # formlayout
	} # vbox
      } # generalOptionsGroupBox

      # dates group box  BL
      groupbox { # datesGroupBox
        title tr('Dates')
        date { # minimumDateEdit
          displayFormat 'MMM d yyyy'
          dateRange Const::MinimumDate, Const::MaximumDate
          connector :minimumDate
          labeltext tr('&Minimum Date:')
        }
        date { # currentDateEdit
          displayFormat 'MMM d yyyy'
          dateRange Const::MinimumDate, Const::MaximumDate
          connector :selectedDate
          labeltext tr('&Current Date:')
        }
        date { # maximumDateEdit
          displayFormat 'MMM d yyyy'
          dateRange Const::MinimumDate, Const::MaximumDate
          connector :maximumDate
          labeltext tr('Ma&ximum Date:')
        }
      } # dateGroupBox
      # textformats group box  BR
      groupbox { # TextFormatsGroupBox
        title tr('Text Formats')
	vbox {
	  formlayout {
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
	      currentIndex 2
	      labeltext tr('&Weekday color:')
	      whenActivated do |data, key|
	  	#tag "whenActivated(#{data}, #{key.inspect})"
		format = Qt::TextCharFormat.new
		format.foreground = Qt::Brush.new(Reform::Graphical::make_color(data))
		calendarWidget.setWeekdayTextFormat(Qt::Monday, format);
		calendarWidget.setWeekdayTextFormat(Qt::Tuesday, format);
		calendarWidget.setWeekdayTextFormat(Qt::Wednesday, format);
		calendarWidget.setWeekdayTextFormat(Qt::Thursday, format);
		calendarWidget.setWeekdayTextFormat(Qt::Friday, format);
	      end
	    }
	    combobox { # weekendColorCombo
	      struct Const::PossibleColors
	      currentIndex 0
	      labeltext tr('Week&end color:')
	      whenActivated do |data, key|
		(format = Qt::TextCharFormat.new).foreground = Qt::Brush.new(Reform::Graphical::make_color(data))
		calendarWidget.setWeekdayTextFormat Qt::Saturday, format
		calendarWidget.setWeekdayTextFormat Qt::Sunday, format
	      end
	    }
	    combobox {
	      struct tr('Bold'), tr('Italic'), tr('Green'), tr('Plain')
	      labeltext tr('&Header text:')
	      whenActivated do |data, key|
		format = Qt::TextCharFormat.new
		case key
		when 0 then format.fontWeight = Qt::Font::Bold
		when 1 then format.fontItalic = true
		when 2 then format.foreground = Qt::Brush.new(Qt::green)
		end
		tag "set headerTextFormat"
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
	  } # formlayout
	  hbox { # checkBoxLayout
	    checkbox {
	      name :firstFridayCheckbox
	      text tr('&First Friday in blue')
	      whenToggled { |checked| calendarModel.model_touch }
	    }
	    spacer stretch: 1
	    checkbox {
	      name :mayFirstCheckbox
	      text tr('May &1 in red')
	      whenToggled { calendarModel.model_touch }
	    }
	  } # hbox
	} # vbox
      } # textFormatsGroupBox
    }  # layout
#     tag "setting whenConnected form callback"
       # FIXME: once set, this is never unset and I cannot find how the original
       # example does this.
    whenConnected do |model, propa|
#      tag "whenConnected"
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
