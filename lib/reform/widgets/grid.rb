
#  Copyright (c) 2013 Eugene Brazwick

require_relative '_layout'

module R::Qt
  class GridLayout < Layout

    public # methods of GridLayout

    # override. We must re-add all children, unfortunately.
    # Because at the time of adding they were not setup yet.
      def setup hash = nil, &initblock
	super
	#tag "#{self.class}::setup, cc = #{columnCount}"
	col, row = 0, 0
	ncols = columnCount
	each_child do |control|
	  next unless Layout::Able === control
	  c, r = col, row
	  spanc, spanr = control.span
	  spanc = [1, ncols - c].max if spanc == :all_remaining
	  #tag "span = #{spanc}, #{spanr}"
	  # according to manual, addX takes parentship, so it is safe to re-add an item
	  case control
	  when Layout
	    addLayout control, r, c, spanr, spanc
	  when Widget
	    addWidget control, r, c, spanr, spanc
	  end
	  ncols = c + spanc if c + spanc > ncols
	  col, row = c + spanc, r
	  col, row = 0, row + 1 if col >= ncols
	end
	#tag "#{self.class}::setup OK"
      end

      attr_dynamic Fixnum, :columnCount

      alias columncount columnCount
      alias colcount columnCount
      alias columns columnCount

  end

  Reform.createInstantiator __FILE__, GridLayout
end # module R::Qt
