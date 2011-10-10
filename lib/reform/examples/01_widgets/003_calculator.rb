#!/usr/bin/ruby
#encoding : utf-8
# Note that I use a 'x2' from the utf-8 encoding 
# and also the special 'x' character.

# Copyright (c) 2010-2011 Eugene Brazwick

# Please see examples 001 and 002 first

require 'reform/app'

Reform::app {
  # applications can have several forms but let's start with one
  # a 'dialog' is a form that is not resizable by default
  dialog {
    # 'tr' is a Qt method. Support for multilanguage apps is however zero
    # at the moment. It shows that you can call any ruby method
    windowTitle tr('Calculator')
    calculator_model { 
      # the author states that the preferred name is :calculatorModel
      # Anyway, assigning a name gives the form an ad-hoc method with the
      # given name that refers to the control, widget or model that is named.
      name :calculator 
      #track_propagation true
    }
    # We add a Qt layout to the form where all widgets are inserted
    # A gridlayout can be given a nr of columns.
    gridlayout {
      # here we specify that the layout is non resizeable
      fixedsize
      # and since no other specs are present it depends a bit
      # on how wide the edit will be. So this is a bit of a gamble
      # but it can easily be nailed using 'colcount 6' for example
      #
      # an 'edit' is an editable input control. Except that we
      # make it readonly. Because it's a cheap way to make the area
      # look good.
      edit {
        # here is said how the contents relates to the given model
	# (the calculatormodel above). We use its 'display'
	# value.
	connector :display
	# any control can give some hints to the gridlayout it is 
	# a part of. In this case our edit counts a 6 columns
        colspan 6
	# the initial text. I believe this is pretty useless 
#        text '0'
	# by default the connector is checked for 'rw'ness. 
	# since calculator has a method 'display=()' the edit would
	# be alterable by the user, but we don't want that here.
        readOnly true
	# alignment of the text:
        rightalign
	# How many characters can be put inside.
        maxLength 15
	# this is rather ugly:
        f = font
        f.pointSize += 8
        font f
	# But it does show any ruby code can be put here
      }
      # the spacy toolbutton was just created for this example
      spacy_toolbutton { # backspace
        text tr('Backspace')
	# the top 3 buttons are wider than the rest
        colspan 2
	# This is an event handler. 
	# Note that the code executed is run on the dialog.
	# ie, our 'dialog' as defined above is 'self'.
	# Hence, we can use 'calculator' to refer to our datamodel
	# In the end, the model internals will assign something to
	# calculator.display and that will change what's inside the
	# edit-control.
        whenClicked { calculator.enterBackspace }
      }
      # All following buttons do similar things.
      # every one of them has a text, a width and an event handler
      # Well, it is actually possible of creating a ruby method
      # that would make it a bit dry-er.
      spacy_toolbutton { # clear
        text tr('Clear')
        colspan 2
        whenClicked { calculator.clear }
      }
      spacy_toolbutton { # clearAll
        text tr('Clear All')
        colspan 2
        whenClicked { calculator.clearAll }
      }
      spacy_toolbutton { # clearMemory
        text tr('MC')
        whenClicked { calculator.clearMemory }
      }
      spacy_toolbutton {
        text tr('7')
        whenClicked { calculator.enterDigit '7' }
      }
      spacy_toolbutton {
        text tr('8')
        whenClicked { calculator.enterDigit '8' }
      }
      spacy_toolbutton {
        text tr('9')
        whenClicked { calculator.enterDigit '9' }
      }
      spacy_toolbutton {
        text '÷'
        whenClicked { calculator.enterMultiplicativeOperator :div }
      }
      spacy_toolbutton {
        text 'Sqrt'
        whenClicked { calculator.enterUnaryOperator :sqrt }
      }
      spacy_toolbutton {
        text tr('MR')
        whenClicked { calculator.readMemory }
      }
      spacy_toolbutton {
        text tr('4')
        whenClicked { calculator.enterDigit '4' }
      }
      spacy_toolbutton {
        text tr('5')
        whenClicked { calculator.enterDigit '5' }
      }
      spacy_toolbutton {
        text tr('6')
        whenClicked { calculator.enterDigit '6' }
      }
      spacy_toolbutton {
        # note: the chars can be inserted using charmap, pick 'common'
        # for script, not 'latin'
        text '×'
        whenClicked { calculator.enterMultiplicativeOperator :mult }
      }
      spacy_toolbutton {
        text '×²'
        whenClicked { calculator.enterUnaryOperator :sqr }
      }
      spacy_toolbutton {
        text tr('MS')
        whenClicked { calculator.setMemory }
      }
      spacy_toolbutton {
        text tr('1')
        whenClicked { calculator.enterDigit '1' }
      }
      spacy_toolbutton {
        text tr('2')
        whenClicked { calculator.enterDigit '2' }
      }
      spacy_toolbutton {
        text tr('3')
        whenClicked { calculator.enterDigit '3' }
      }
      spacy_toolbutton {
        text tr('-')
        whenClicked { calculator.enterAdditiveOperator :sub }
      }
      spacy_toolbutton {
        text tr('1/x')
        whenClicked { calculator.enterUnaryOperator :reciprocal }
      }
      spacy_toolbutton {
        text tr('M+')
        whenClicked { calculator.addToMemory }
      }
      spacy_toolbutton {
        text tr('0')
        whenClicked { calculator.enterDigit '0' }
      }
      spacy_toolbutton {
        text '.'
        whenClicked { calculator.enterPoint }
      }
      spacy_toolbutton {
        text '±'
        whenClicked { calculator.enterChangeSign }
      }
      spacy_toolbutton {
        text '+'
        whenClicked { calculator.enterAdditiveOperator :add }
      }
      spacy_toolbutton {
        text '='
        whenClicked { calculator.enterEquals }
      }
    }
  }
}
