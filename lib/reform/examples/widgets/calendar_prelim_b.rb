#!/usr/bin/ruby -w

# Copyright (c) 2010 Eugene Brazwick

require 'reform/app'

class Const < Qt::Object
  MinimumDate = '01-01-1900'
  MaximumDate = '01-01-3000'
end

Reform::app {
  gridlayout { # previewLayout, stupid layout with 1 control only, should be better syntax

    calendarwidget {
      name :calendarWidget
      # this silently ignores illegal inputs:
      minimumDate Const::MinimumDate   # dd-mm-yy(yy)? or yyyy.mm.dd or mm[^-]dd[^-]yy(yy)?
      maximumDate Const::MaximumDate   # or dd.MMM.yy(yy)? or MMM.dd.yy(yy)?
                                # or yy(yy)?.MMM.dd
                                # or split in three triple integers y m d
                                # or int/string triples dMy yMd Mdy as long y > 31
      gridVisible true
      whenMonthChanged { }
      makecenter
    }
    # FIXME, ugly
    # proposed:  row[0] { minimumHeight value }
    # so a method 'row' that creates a dummy object with '[]' as method, accepting
    # a block too.
    # however, I have the feeling this should not be here to begin with.
#     setRowMinimumHeight(0, @containing_form.calendarWidget.sizeHint.height)
#     setColumnMinimumWidth(0, @containing_form.calendarWidget.sizeHint.width)
  }
}