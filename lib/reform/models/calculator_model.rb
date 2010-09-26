=begin
 ***************************************************************************
 **
 ** Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
 ** All rights reserved.
 ** Contact: Nokia Corporation (qt-info@nokia.com)
 **
 ** This file is part of the examples of the Qt Toolkit.
 **
 ** $QT_BEGIN_LICENSE:LGPL$
 ** Commercial Usage
 ** Licensees holding valid Qt Commercial licenses may use this file in
 ** accordance with the Qt Commercial License Agreement provided with the
 ** Software or, alternatively, in accordance with the terms contained in
 ** a written agreement between you and Nokia.
 **
 ** GNU Lesser General Public License Usage
 ** Alternatively, this file may be used under the terms of the GNU Lesser
 ** General Public License version 2.1 as published by the Free Software
 ** Foundation and appearing in the file LICENSE.LGPL included in the
 ** packaging of this file.  Please review the following information to
 ** ensure the GNU Lesser General Public License version 2.1 requirements
 ** will be met: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
 **
 ** In addition, as a special exception, Nokia gives you certain additional
 ** rights.  These rights are described in the Nokia Qt LGPL Exception
 ** version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
 **
 ** GNU General Public License Usage
 ** Alternatively, this file may be used under the terms of the GNU
 ** General Public License version 3.0 as published by the Free Software
 ** Foundation and appearing in the file LICENSE.GPL included in the
 ** packaging of this file.  Please review the following information to
 ** ensure the GNU General Public License version 3.0 requirements will be
 ** met: http://www.gnu.org/copyleft/gpl.html.
 **
 ** If you have questions regarding the use of this file, please contact
 ** Nokia at qt-info@nokia.com.
 ** $QT_END_LICENSE$
 **
 ****************************************************************************/
=end

# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../model'

=begin rdoc

This represents the model of the calculator used in Qt's examples/widgets/calculator.cpp
Minor tweaks added.

The model is decoupled from the gui, as opposed to the original Qt example.

This demonstrates that ANY ruby class can easily be a model in the 'reform' system.
=end
  class CalculatorModel < AbstractModel
    private
    def initialize parent, q = nil
      super
      clearAll
    end

    def f2s arg
      arg.to_s.sub(/\.0*$|(\.[0-9]*[1-9]+)0+$/, '\1')
    end

    def abortOperation
      clearAll
      self.display = '####'
    end

    def calculate rightOperand, pendingOperator
      case pendingOperator
      when :add
        @sumSoFar += rightOperand
      when :sub
        @sumSoFar -= rightOperand
      when :mult
        @factorSoFar *= rightOperand
      when :div
        return abortOperation if rightOperand == 0.0
        @factorSoFar /= rightOperand
      end
      true
    end

    # make a float out of @display
    def display_to_f
      case @display
      when 'Infinity' then 1.0 / 0.0
      when '-Infinity' then -1.0 / 0.0
      else Float(@display[-1] == '.' ? @display + '0' : @display)
      end
    end

    public

    # this is a string and can be incomplete, like '3.'
    # It is not localized. dynamic_accessor causes dynamicPropertyChanged to be called
    # and with that connectModel
    dynamic_accessor :display

    # digit is a single char string from '0' to '9'.
    def enterDigit val
      return if @display == '0' && val == '0'
      if @waitingForOperand
        @display = '0'
        @waitingForOperand = false
      end
      # changed from example: how can Nokia example even work?
      tag "calling display=()"
      self.display = f2s(@display == '0' ? val : @display + val)
    end

    # clear current number input (and only that).
    def clear
      return if @waitingForOperand
      self.display = '0'
      @waitingForOperand = true
    end

    # reinitialize the model
    def clearAll
      # value in M,  accumulated sum,  temporary for multiplications and divisions
      @sumInMemory = @sumSoFar = @factorSoFar = 0
      # expecting numeric input
      @waitingForOperand = true
      # last multiplicative operator entered by user
      @pendingMultiplicativeOperator = nil
      # last additive operator entered by user
      @pendingAdditiveOperator = nil
      self.display = '0'
    end

    # opsym can be :sqrt, :sqr, :reciprocal
    # execute operator on current operand
    def enterUnaryOperator opsym
      operand = display_to_f
      result = 0.0
      case opsym
      when :sqrt
        abortOperation if operand < 0.0
        begin
          result = Math.sqrt(operand)
        rescue Errno::EDOM
          self.display = '####'
          @waitingForOperand = true
          return
        end
      when :sqr
        result = operand * operand
      when :reciprocal
        abortOperation if operand == 0.0
        result = 1.0 / operand
      end
      self.display = f2s(result)
      @waitingForOperand = true
    end

    # opsym can be :add or :sub
    # if multiplication is queued, execute it first
    # if addition was queued, execute it
    # queue the current addition
    def enterAdditiveOperator opsym
      operand = display_to_f
      if @pendingMultiplicativeOperator
        return unless calculate(operand, @pendingMultiplicativeOperator)
        self.display, @factorSoFar = f2s(operand = @factorSoFar), 0.0
        @pendingMultiplicativeOperator = nil
      end
      if @pendingAdditiveOperator
        return unless calculate(operand, @pendingAdditiveOperator)
        self.display = f2s(@sumSoFar)
      else
        @sumSoFar = operand
      end
      @pendingAdditiveOperator = opsym
      @waitingForOperand = true
    end

    # we support :mult and :div
    # if a multiplication was queued, execute it
    # then queue this multiplication
    def enterMultiplicativeOperator opsym
      operand = display_to_f
      if @pendingMultiplicativeOperator
        return unless calculate(operand, @pendingMultiplicativeOperator)
        self.display = f2s(@factorSoFar)
      else
        @factorSoFar = operand
      end
      @pendingMultiplicativeOperator = opsym
      @waitingForOperand = true
    end

    # execute pending calculations in the queue, and display the result
    def enterEquals
      operand = display_to_f
      if @pendingMultiplicativeOperator
        return unless calculate(operand, @pendingMultiplicativeOperator)
        operand, @factorSoFar = @factorSoFar, 0.0
        @pendingMultiplicativeOperator = nil
      end
      if @pendingAdditiveOperator
        return unless calculate(operand, @pendingAdditiveOperator)
        @pendingAdditiveOperator = nil
      else
        @sumSoFar = operand
      end
      self.display = f2s(@sumSoFar)
      @sumSoFar = 0.0
      @waitingForOperand = true
    end

    # erases previous result, then adds '.' at end
    def enterPoint
      @display = '0' if @waitingForOperand
      self.display = @display + '.'
      @waitingForOperand = false
    end

    # if negative number make it positive and vice versa
    def enterChangeSign
      text = @display.dup # !!
#       tag "text='#{text}', op=#{display_to_f}"
      if (operand = display_to_f) > 0.0
        text = '-' + text
      elsif operand < 0.0
        text[0, 1] = ''  # this mutates text, so beware it is not @display
      end
#       tag "assign '#{text}'"
      self.display = text
    end

    # erase last char. If empty string would be returned, use '0' instead
    def enterBackspace
      return if @waitingForOperand
      text = @display.chop
#       tag "text='#{text}'"
#       text.chop!  AARGHHHH
      if text.empty?
        text = '0'
        @waitingForOperand = true
      end
#       tag "Assigning new text '#{text}' to DYNAMIC property"
      self.display = text
    end

    # clear internal sum
    def clearMemory
      @sumInMemory = 0.0
    end

    # display internal sum, erasing the current number
    def readMemory
      self.display = f2s(@sumInMemory)
      @waitingForOperand = true
    end

    # execute pending calculations and store the result in the memory slot
    def setMemory
      enterEquals
      @sumInMemory = display_to_f
    end

    # execute pending calculations, then add the result to the value in memory
    def addToMemory
      enterEquals
      @sumInMemory += display_to_f
    end

  end # class CalculatorModel

#   tag "Creating instantiator"
  createInstantiator File.basename(__FILE__, '.rb'), nil, CalculatorModel

end # Reform