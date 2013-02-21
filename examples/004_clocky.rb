
# Copyright (c) 2013 Eugene Brazwick
#
# you can run this program from anywhere using 
# RUBYLIB=<installpath>/Midibox/lib ruby <installpath>/Midibox/examples/004_clocky.rb

require 'reform/app'

Reform::app {
  # the default interval is 100ms which only increases the load.
  # Now with this coarse interval is technically possible that the colon is a little out of sync.
  time_model interval_ms: 1000 
  lcdnumber {
    size 200, 80
    title 'Digital Clocky'
    # the more generic solution:
    #connector -> time { time.strftime(time.sec % 2 == 0 ? '%H %M' : '%H:%M') }
    # But secretly Qt::LCDNumber has support for Qt::Timer as well as ruby ::Time.
    connector :now
  } # lcdnumber
} # app
