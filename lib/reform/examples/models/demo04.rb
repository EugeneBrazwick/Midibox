
# Copyright (c) 2010 Eugene Brazwick

require 'reform/app'

Reform::app {
  form {
    simpledata :blue
    combo {
      simpledata red: 'hot', blue: 'cold', green: 'OK', magenta: 'pretty',
                 darkBlue: 'watery', white: 'pure', black: 'evil'
      connector  :self
    }
    canvas {
      simpletext {
#         tag "HEU??, self = #{self}, Ah I see, color is a method of ALL graphic items "
        text 'Qt'
#         color connector: :self                        #VERY BAD
        brush connector: :self
      }
    }
  }
}