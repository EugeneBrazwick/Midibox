#!/usr/bin/ruby
#encoding : utf-8

# Copyright (c) 2010 Eugene Brazwick

require 'reform/app'

Reform::app {
  dialog {
    windowTitle tr('Calculator')
         # the author states that the preferred name is :calculatorModel
         # this makes the code a lot clearer, if not to say 'crisp'
    calculator_model { name :calculator }
    gridlayout {
      fixedsize
      edit {
        name :display
        text '0'
        readOnly true
        rightalign
        maxLength 15
        colspan 6
        f = font
        f.pointSize += 8
        font f
      }
      spacy_toolbutton { # backspace
        text tr('Backspace')
        colspan 2
        whenClicked { calculator.enterBackspace }
      }
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
        whenClicked { tag "whenClicked 8 called"; calculator.enterDigit '8' }
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