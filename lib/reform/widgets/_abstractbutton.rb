
#  Copyright (c) 2013 Eugene Brazwick

require_relative 'widget'

module R::Qt
  class AbstractButton < Widget 

    private # methods of AbstractButton

      signal 'clicked(bool)'

      def value arg = nil
	return @value unless arg
	@value = arg
      end

    public # methods of AbstractButton

      attr_dynamic String, :text

      def apply_model data
	# ignore
      end

      def setup hash = nil, &initblock
	super
	if connector
	  clicked do |checked|
	    push_data @value
	  end
	end
      end

  end # class AbstractButton
end # module Qt

