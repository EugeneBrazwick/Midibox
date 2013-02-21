
#  Copyright (c) 2013 Eugene Brazwick

require_relative 'frame'

module R::Qt
  class LCDNumber < Frame
    public # methods of LCDNumber

      # override
      def apply_model data
	case data
	when Timer, ::Time then display data.strftime(data.sec % 2 == 0 ? '%H %M' : '%H:%M') 
	else display data
	end
      end

      attr_dynamic Fixnum, :digitCount
      attr_dynamic Symbol, :segmentStyle

      alias segments segmentStyle
      alias display= display

  end # class LCDNumber 

  Reform.createInstantiator __FILE__, LCDNumber
end
