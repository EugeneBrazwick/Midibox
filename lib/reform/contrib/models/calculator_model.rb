
=begin
/****************************************************************************
**
** Copyright (C) 2012 Digia Plc and/or its subsidiary(-ies).
** Contact: http://www.qt-project.org/legal
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** You may use this file under the terms of the BSD license as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of Digia Plc and its Subsidiary(-ies) nor the names
**     of its contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/
=end

# Copyright (c) 2010-2013 Eugene Brazwick

module R::Qt

  require_relative '../../model'

  class CalculatorModel < Model
      
      DisplayErrorStr = '####'

    private # methods of CalculatorModel

      def initialize *args
	super
	clearAll
      end

      # strip off trailing zeroes behind the decimal point
      # strip off decimal point too if only zeroes follow
      #	12.34	-> 12.34
      #	12.30	-> 12.3
      #	12.00	-> 12
      def self.f2s arg
	arg.to_s.sub /\.0*$|(\.[0-9]*[1-9]+)0+$/, '\1'
      end

      def abortOperation
	clearAll
	self.display = DisplayErrorStr
	false
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
	  return abortOperation if rightOperand == 0
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

      # this is a string and can be incomplete, like '3.'
      # It is not localized. 
      def display= value
	@display = value
	model_propagate
      end

      # digit is a single char string from '0' to '9'.
      def enterDigit val, sender = nil
	#tag "enterDigit(#{val}), display='#@display'"
	return if @display == '0' && val == '0'
	if @waitingForOperand
	  @display = '0'
	  @waitingForOperand = false
	end
	# changed from example: how can Nokia example even work?
	#tag "calling self.display=()"
	self.display = CalculatorModel::f2s(@display == '0' ? val : @display + val)
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
	    self.display = DisplayErrorStr
	    @waitingForOperand = true
	    return
	  end
	when :sqr
	  result = operand * operand
	when :reciprocal
	  abortOperation if operand == 0.0
	  result = 1.0 / operand
	end
	self.display = CalculatorModel::f2s(result)
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
	  self.display, @factorSoFar = CalculatorModel::f2s(operand = @factorSoFar), 0.0
	  @pendingMultiplicativeOperator = nil
	end
	if @pendingAdditiveOperator
	  return unless calculate(operand, @pendingAdditiveOperator)
	  self.display = CalculatorModel::f2s(@sumSoFar)
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
	  self.display = CalculatorModel::f2s(@factorSoFar)
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
	self.display = CalculatorModel::f2s(@sumSoFar)
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
	if (operand = display_to_f) > 0.0
	  text = '-' + text
	elsif operand < 0.0
	  text[0, 1] = ''  # this mutates text, so beware it is not @display
	end
	self.display = text
      end

      # erase last char. If empty string would be returned, use '0' instead
      def enterBackspace
	return if @waitingForOperand
	text = @display.chop
	if text.empty?
	  text = '0'
	  @waitingForOperand = true
	end
	self.display = text
      end

      # clear internal sum
      def clearMemory
	@sumInMemory = 0.0
      end

      # display internal sum, erasing the current number
      def readMemory
	self.display = CalculatorModel::f2s(@sumInMemory)
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
    
      attr :display

      # write-only connector
      def enter= symbol
	case symbol
	when :backspace then enterBackspace
	when 0..9 then enterDigit symbol.to_s
	when :sqrt, :sqr, :reciprocal then enterUnaryOperator symbol
	when :add, :sub then enterAdditiveOperator symbol
	when :mult, :div then enterMultiplicativeOperator symbol
	when :equals then enterEquals
	when :point then enterPoint
	when :changeSign then enterChangeSign
	else send symbol
	end
      end

      def enter; end

    public # methods of CalculatorModel


  end # class CalculatorModel

  Reform.createInstantiator __FILE__, CalculatorModel
end # module Reform
