
require 'reform/app'
require_relative '../../models/calendar_model'
require_relative '../../widgets/calendarwidget'

Reform::app {
  groupbox { # generalOptionsGroupBox
    title tr('General Options')
    size 480, 300
#     formlayout { # outerLayout
      combobox { # localeCombo
        # use Qt locale languagelist, and for each locale add the
        # countriesForLanguage(lang).
        # the currentlocale must be made the default value and thus function
        # as the 'connecting' modelpart, we should simply set calendar.language_and_country
        name :language_and_country
        model ['something']
        labeltext tr('&Locale')  # quicky label association, becomes a 'buddy'
      }
      combobox { # firstDayCombo
        # or datasource({k=>v,...}) or datasource Hash[k=>v,...]
        model CalendarModel::WeekDaysFromSun2Sat
        name :weekstart  # should return a Qt::XXXday
      }
      # as demo, I write it in full, but could place 'label' in combobox here as well
      label { # firstDayLabel
        text tr('Wee&k starts on:')
        buddy :weekstart
      }
      combobox { # selectionModeCombo
        model CalendarWidget::PossibleSelections
        labeltext tr('&Selection mode:')
      }
       hbox { # checkBoxLayout
# FIXME: these are missing !!!!  hbox fails here, checkbox works fine!!!
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
      combobox {# horizontalHeaderCombo
        name :horizontalHeaderOption
        model CalendarWidget::PossibleHorizontalHeaderOptions
        currentIndex 1  # this alters the model on initialization, even!!
        labeltext tr('&Horizontal header:')
      }
      combobox { # verticalHeaderCombo
        model CalendarWidget::PossibleVerticalHeaderOptions
        labeltext tr('&Vertical header:')
      }
#     }  # formlayout
  } # generalOptionsGroupBox
}