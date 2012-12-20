
require 'reform/app'
require_relative '../../models/calendar_model'
require_relative '../../widgets/calendarwidget'

Reform::app {
  groupbox { # generalOptionsGroupBox
    title tr('General Options')
    sizeHint 480, 300
    grid {
      formlayout {
	combobox { # localeCombo
	  # use Qt locale languagelist, and for each locale add the
	  # countriesForLanguage(lang).
	  # the currentlocale must be made the default value and thus function
	  # as the 'connecting' modelpart, we should simply set calendar.language_and_country
	  connector :language_and_country
	  struct 'just', 'a', 'test', 'array', 'of', 'data'
	  labeltext tr('&Locale')  # quicky label association, becomes a 'buddy'
	}
	combobox { # firstDayCombo
	  # or datasource({k=>v,...}) or datasource Hash[k=>v,...]
	  struct Reform::CalendarModel::WeekDaysFromSun2Sat
	  connector :weekstart  # should return a Qt::XXXday
	  name :weekstart # to attach the label to
	}
	# as demo, I write it in full, but could place 'label' in combobox here as well
	label { # firstDayLabel
	  text tr('Wee&k starts on:')
	  buddy :weekstart
	}
	combobox { # selectionModeCombo
	  struct Reform::CalendarWidget::PossibleSelections
	  labeltext tr('&Selection mode:')
	}
      }
      hbox { # checkBoxLayout
        checkbox { # gridCheckBox
          text tr('&Grid')
          name :gridVisible?
        }
        spacer stretch: 1 # stretchable open space in between
        checkbox { # navigationCheckBox
          text tr('&Navigation Bar')
          checked true
        }
      } # hbox
      formlayout {
	combobox {# horizontalHeaderCombo
	  connector :horizontalHeaderOption
	  struct Reform::CalendarWidget::PossibleHorizontalHeaderOptions
	  currentIndex 1  # this alters the model on initialization, even!!
	  labeltext tr('&Horizontal header:')
	}
	combobox { # verticalHeaderCombo
	  struct Reform::CalendarWidget::PossibleVerticalHeaderOptions
	  labeltext tr('&Vertical header:')
	}
      }
    }  # grid
  } # generalOptionsGroupBox
}

