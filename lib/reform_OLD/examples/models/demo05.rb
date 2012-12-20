
# Copyright (c) 2010 Eugene Brazwick

require 'reform/app'

Reform::app {
  timer # our data source, updated each second by default
  edit connector: :to_s # displays timer.to_s
}
