#!/usr/bin/ruby -w

# Copyright (c) 2010 Eugene Brazwick

require 'reform/app'

class Const < Qt::Object
  MinimumDate = '01-01-1900'
  MaximumDate = '01-01-3000'
end

Reform::app {
#   groupbox {
    # this setup is a failure for some reason. At this point calendar.rb got into the groove
    # however. What's the use of groupbox???
    # leaving it out shows that makecenter works even on its own....
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
      makecenter # this induces a gridlayout!
    }
#   }
}