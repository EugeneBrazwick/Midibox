
#  Copyright (c) 2013 Eugene Brazwick

require_relative '_layout'

module R::Qt
  class GridLayout < Layout
    private # methods of GridLayout
      def initialize *args
	super
	@currow = @curcol = 0
      end

    public # methods of GridLayout

      attr_dynamic Fixnum, :columnCount

      alias columncount columnCount
      alias colcount columnCount
      alias columns columnCount

  end

  Reform.createInstantiator __FILE__, GridLayout
end # module R::Qt
