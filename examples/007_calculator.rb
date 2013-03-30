
# Copyright (c) 2010-2013 Eugene Brazwick

require 'reform/app'

Reform::app {
  failOnErrors true
  # Digia Plc subclasses QWidget. There is no need for such things in Ruby
  widget {
    title 'Calculator'
    calculator_model
    grid {
      sizeConstraint :fixed
      edit {
	connector :display
	colspan 6
	readOnly true
	alignment :right
	maxLength 15
	font.pointSize += 8
      } # edit
      spacy_toolbutton { # backspace
        text 'Backspace'
	connector :enter
	value :backspace
	# the top 3 buttons are wider than the rest
        colspan 2
      }
      spacy_toolbutton { # clear
        text 'Clear'
	connector :enter
	value :clear
        colspan 2
      }
      spacy_toolbutton text: 'Clear All', connector: :enter, value: :clearAll, colspan: 2
      # the next bunch could have been done using a Hash.each too:
      spacy_toolbutton text: 'MC', connector: :enter, value: :clearMemory
      spacy_toolbutton text: '7', connector: :enter, value: 7
      spacy_toolbutton text: '8', connector: :enter, value: 8
      spacy_toolbutton text: '9', connector: :enter, value: 9
      spacy_toolbutton text: '÷', connector: :enter, value: :div
      spacy_toolbutton text: 'Sqrt', connector: :enter, value: :sqrt
      spacy_toolbutton text: 'MR', connector: :enter, value: :readMemory
      spacy_toolbutton text: '4', connector: :enter, value: 4
      spacy_toolbutton text: '5', connector: :enter, value: 5
      spacy_toolbutton text: '6', connector: :enter, value: 6
      spacy_toolbutton text: '×', connector: :enter, value: :mult
      spacy_toolbutton text: '×²', connector: :enter, value: :sqr
      spacy_toolbutton text: 'MS', connector: :enter, value: :setMemory
      spacy_toolbutton text: '1', connector: :enter, value: 1
      spacy_toolbutton text: '2', connector: :enter, value: 2
      spacy_toolbutton text: '3', connector: :enter, value: 3
      spacy_toolbutton text: '-', connector: :enter, value: :sub
      spacy_toolbutton text: '1/x', connector: :enter, value: :reciprocal
      spacy_toolbutton text: 'M+', connector: :enter, value: :addToMemory
      spacy_toolbutton text: '0', connector: :enter, value: 0
      spacy_toolbutton text: '.', connector: :enter, value: :point
      spacy_toolbutton text: '±', connector: :enter, value: :changeSign
      spacy_toolbutton text: '+', connector: :enter, value: :add
      spacy_toolbutton text: '=', connector: :enter, value: :equals
    } # grid
  } # widget
} # app
