
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
#       tag "#{self.class}.new, qtc=#{qtc}" # ???? caller=#{caller.join("\n")}"
#       @fill = [] # array of rows where each row is a bool array
      # an item in a grid can set col, row and colspan and rowspan
      @currow, @curcol = 0, 0
      @collection = []
    end

    def columnstretch ar
      ar.each_with_index { |v, i| @qtc.setColumnStretch(i, v) }
    end

    def setRowMinimumHeight row, h
      @qtc.setRowMinimumHeight row, h
    end

    def setColumnMinimumWidth row, h
      @qtc.setColumnMinimumWidth row, h
    end

    public
    #override
    def addWidget control, qt_widget = nil
      @collection << control
#       tag "addWidget to grid"
# #       @qtc.addWidget qt_widget, @currow, @curcol, @currowspan, @curcolspan
# #       skip
#       span
    end

    # override
    def postSetup
#       tag "#{self}::postSetup"
      curcol, currow = 0, 0
      for control in @collection
        r, c = control.layoutpos
        r, c = currow, curcol if r.nil?
        spanr, spanc = control.span
        spanr, spanc = 1, 1 if spanr.nil?
#         tag "qtc.addWidget(#{control}, r:#{r}, c:#{c}, #{spanr}, #{spanc}), layout?->#{control.layout?}"
        if control.layout?
          @qtc.addLayout(control.qtc, r, c, spanr, spanc)
        elsif alignment = control.layout_alignment
#           tag "applying alignment: #{alignment}, ignoring span"
          @qtc.addWidget(control.qtc, r, c, alignment)
        else
#           tag "addWidget(#{control.qtc}, r=#{r}, c=#{c}, spanr=#{spanr}, spanc=#{spanc})"
          @qtc.addWidget(control.qtc, r, c, spanr, spanc)
        end
        currow, curcol = r, c + spanc
        curcol, currow = 0, currow + 1if curcol >= @qtc.columnCount
      end
      # a bit of a hack, but probably what you want:
      if @collection.length == 1 && @collection[0].layout_alignment == Qt::AlignCenter
#         tag "APPLYING sizehint to single centered widget in a grid"
        @qtc.setRowMinimumHeight(0, @collection[0].qtc.sizeHint.height)
        @qtc.setColumnMinimumWidth(0, @collection[0].qtc.sizeHint.width)
      end
      remove_instance_variable :@collection
    end

  end # class GridLayout

  createInstantiator File.basename(__FILE__, '.rb'), Qt::GridLayout, GridLayout

end # Reform