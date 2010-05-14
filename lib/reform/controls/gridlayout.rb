
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../layout'

=begin
MAJOR HEADACHE CODE

Note that we always do this:
    instantiate qtctrl assigning it to qparentwidget
    instantiate control
    add control to parent, using parent.addControl
    execute setupblock for control
    call postSetup on control

The original design used this syntax:
  gridlayout {
      edit {}
      ...
      goto 4,4
      edit {}...
      span 1, 6
      edit {} ...
}
However, that is not declarative...

It must be
gridlayout {
  edit { span 1,6 }
  edit { layoutpos 0, 1 }
=end
  class GridLayout < Layout
  private
    def initialize parent, qtc
      super
#       @fill = [] # array of rows where each row is a bool array
      # an item in a grid can set col, row and colspan and rowspan
      @currow, @curcol = 0, 0
      @collection = []
    end

    def columnstretch ar
      ar.each_with_index { |v, i| @qtc.setColumnStretch(i, v) }
    end

    public
    #override
    def addWidget control, qt_widget
      @collection << control
#       tag "addWidget to grid"
# #       @qtc.addWidget qt_widget, @currow, @curcol, @currowspan, @curcolspan
# #       skip
#       span
    end

    # override
    def postSetup
      curcol, currow = 0, 0
      for control in @collection
        r, c = control.layoutpos
        r, c = currow, curcol if r.nil?
        spanr, spanc = control.span
        spanr, spanc = 1, 1 if spanr.nil?
#         tag "qtc.addWidget(#{control}, #{r}, #{c}, #{spanr}, #{spanc})"
        @qtc.addWidget(control.qtc, r, c, spanr, spanc)
        currow, curcol = r, c + spanc
        curcol, currow = 0, currow + 1if curcol >= @qtc.columnCount
      end
    end

  end # class GridLayout

  createInstantiator File.basename(__FILE__, '.rb'), Qt::GridLayout, GridLayout

end # Reform