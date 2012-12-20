#!/usr/bin/ruby

require 'reform/app'

Reform::app {
  form {
      #svg width="20cm" height="15cm" viewBox="0 0 800 600"
    sizeHint 800, 600
#     xmlns="http://www.w3.org/2000/svg"
#     xmlns:xlink="http://www.w3.org/1999/xlink/"
#     baseProfile="tiny" version="1.2">
    title tr('Spheres')
    #  Semi-transparent bubbles on a colored background.</desc>
    canvas {

      scene {
        background :white
        # Create radial gradients for each bubble. EXPERIMENTAL
        define { # like the svg 'def' section
          blueBubble brush {
            # alternative syntax:               brush :blueBubble do ....
            radialgradient { # id="blueBubble" gradientUnits="userSpaceOnUse"
                        #cx="0" cy="0" center 0,0
                        #r="100" radius
                        # fx="-50" fy="-50"> focal point
              center 0, 0
              radius 100
              focalpoint -50, -50
              stop offset: 0.0, color: :white
              stop offset: 0.25, color: [205, 205, 255, 166]
              stop offset: 1.0, color: [205, 170, 205, 192]
            } # blueBubble
          }
          redBubble brush {
            radialgradient {
  #             center 0, 0  DEFAULT
              radius 100 # default 1
              focalpoint -50 # default 0,0
              stops 0=>:white, 0.25=>[255,205,205,166], 1.0=>[187,187,153,192]
            }
          }
          greenBubble brush {
            name :greenBubble # " gradientUnits="userSpaceOnUse"
            radialgradient {
              radius 100
              focalpoint -50
              stops 0=>:white, 0.25=>[205, 255, 205, 166], 1.0=>[153,170,170,192]
            }
          }
          yellowBubble brush {
            radialgradient {
              radius 100
              focalpoint -50
              stops 0=>:white, 0.25=>[255, 255, 205, 166], 1.0=>[187,187,170,192]
            }
          }
          surface brush {
            lineargradient start: [-100, 200], stop: [400, 200], stops: {0.0=>[255,255,204], 1.0=>[187,187,136]}
          }
                # - Define a shadow for each sphere.
          shadow shapegroup {
            circle {
              fill :shadowGrad
  #             cx="0" cy="0" r="100" />
              radius 100
            }
          }
          bubble shapegroup {
            circle fill: :black
            circle fill: '#a6ce39', radius: 33
            # M = Absolute move (rel == m) L = lineto, Z = close
            polygon fill: :black, path: [[37,50],[50,37],[12,-1],[22,-11],[10,-24],[-24,10],
                                        [-11,22],[-1,12]]  #  unless ending with :open , the path is closed
            circle radius: 100
          }

        #   Create radial gradients for each circle to make them look like spheres. -->
          blueSphere brush { # " gradientUnits="userSpaceOnUse"
            radialgradient {
              radius 100
              focalpoint -50
              stops 0=>:white, 0.75=>:blue, 1.0=>'#222244'
            }
          }
          redSphere radialgradient radius: 100, focalpoint: -50, stops: { 0=>:white, 0.75=>:red, 1.0=>'#442222' }
          greenSphere radialgradient radius: 100, focalpoint: -50, stops: { 0=>:white, 0.75=>:green, 1.0=>'#113311' }
          yellowSphere radialgradient radius: 100, focalpoint: -50, stops: { 0=>:white, 0.75=>:yellow, 1.0=>'#444422' }
          shadowGrad radialgradient radius: 100, focalpoint: -50, stops: { 0=>:black, 1.0=>'#00000000' }
        } # define
        background radialgradient {
          radius 400
          focalpoint 250
          stops 0=>[255,255,238], 1.0=>[204, 204, 170]
        }
#         rect fill="url(#background)" x="0" y="0" width="800" height="600"   already provided
        transform {
          translate 200, 700
          bubble { fill :blueBubble }
#           animateTransform {
#             attributeName="transform" type="translate" additive="sum"
#             values="0,0; 0,-800" begin="1s" dur="10s" fill="freeze" repeatCount="indefinite"
#           }
        }
        transform {
          translate 315, 700
          transform { scale 0.5
            bubble fill: :redBubble
          }
#           animateTransform { attributeName="transform" type="translate" additive="sum"
#             values="0,0; 0,-800" begin="3s" dur="7s" fill="freeze" repeatCount="indefinite" />
#           }
        }
        transform {
          translate 80, 700
          transform { scale 0.65
            bubble fill: :greenBubble
          }
#           animateTransform { attributeName="transform" type="translate" additive="sum"
#             values="0,0; 0,-800" begin="5s" dur="9s" fill="freeze" repeatCount="indefinite" />
#           }
        }
        transform {
          translate 255, 700
          transform { scale 0.3
            bubble fill: :yellowBubble
          }
#           animateTransform { attributeName="transform" type="translate" additive="sum"
#             values="0,0; 0,-800" begin="2s" dur="6s" fill="freeze" repeatCount="indefinite" />
#           }
        }
        transform {
          translate 565, 700
          transform scale: 0.4, bubble: { fill: :blueBubble }
#           animateTransform { attributeName="transform" type="translate" additive="sum"
#             values="0,0; 0,-800" begin="4s" dur="8s" fill="freeze" repeatCount="indefinite" />
#           }
        }
        transform {
          translate 715, 700
          transform scale: 0.6, bubble: { fill: :redBubble }
#           animateTransform { attributeName="transform" type="translate" additive="sum"
#             values="0,0; 0,-800" begin="1s" dur="4s" fill="freeze" repeatCount="indefinite" />
#           }
        }
        transform {
          translate 645, 700
          transform scale: 0.375, bubble: { fill: :greenBubble }
#           animateTransform { attributeName="transform" type="translate" additive="sum"
#               values="0,0; 0,-800" begin="0s" dur="11s" fill="freeze" repeatCount="indefinite" />
#           }
        }
        transform {
          translate 555, 700
          transform scale: 0.9, bubble: { fill: :yellowBubble }
#           animateTransform { attributeName="transform" type="translate" additive="sum"
#             values="0,0; 0,-800" begin="3s" dur="7.5s" fill="freeze" repeatCount="indefinite" />
#           }
        }
        transform {
          translate 360, 700
          transform scale: 0.5, bubble: { fill: :blueBubble }
#           animateTransform { attributeName="transform" type="translate" additive="sum"
#               values="0,0; 0,-800" begin="3s" dur="6s" fill="freeze" repeatCount="indefinite" />
#           }
        }
        transform {
          translate 215, 700
          transform scale: 0.45, bubble: { fill: :redBubble }
#           animateTransform attributeName="transform" type="translate" additive="sum"
#               values="0,0; 0,-800" begin="5.5s" dur="7s" fill="freeze" repeatCount="indefinite" />
        }
        transform {
          translate 420, 700
          transform scale: 0.75, bubble: { fill: :greenBubble }
#           animateTransform attributeName="transform" type="translate" additive="sum"
#               values="0,0; 0,-800" begin="1s" dur="9s" fill="freeze" repeatCount="indefinite" />
        }
        transform {
          translate 815, 700
          transform scale: 0.6, bubble: { fill: :yellowBubble }
#           animateTransform attributeName="transform" type="translate" additive="sum"
#               values="0,0; 0,-800" begin="2s" dur="9.5s" fill="freeze" repeatCount="indefinite" />
        }

        transform {
          translate 225, 375
          transform {
            scale 1.0, 0.5
            polygon path: [[0, 0],[350,0],[450,450],[-100,450], :close], fill: :surface, stroke: :none
          }
        }

        transform {
          translate 200, 0
          transform {
            translate 200, 490
            scale 2.0, 1.0
            rotate 45
            rect fill:"#a6ce39", position: [-69, -69], size: 138
            circle fill: :black
            circle fill: "#a6ce39", radius: 33
            polygon fill: :black, path: [[37,50],[50,37],[12,-1],[22,-11],[10,-24],[-24,10],
                                         [-11,22],[-1,12], :close]
#             animateTransform attributeName="transform"  type="rotate" additive="sum" values="0; 360"
#                       begin="0s" dur="10s" fill="freeze" repeatCount="indefinite"
          }
          transform {
            translate 200, 375
            shadow transform: { translate: [25,55], scale: [1.0,0.5] }
            circle fill: :blueSphere, radius: 100
          }
          transform {
            translate 315, 440
            scale 0.5
            shadow transform: { translate: [25,55], scale: [1.0,0.5] }
            circle fill: :redSphere, radius: 100
          }
          transform {
            translate 80, 475
            scale 0.65
            shadow transform: { translate: [25,55], scale: [1.0,0.5] }
            circle fill: :greenSphere, radius: 100
          }
          transform {
            translate 255, 525
            scale 0.3
            shadow transform: { translate: [25,55], scale: [1.0,0.5] }
            circle fill: :yellowSphere, radius: 100
          }
        }
      } # scene
    } #canvas
  } # form
} #app


