
# combining canvas with data.
# Everything is data.

require 'reform/app'

Reform::app {
  form {
    # add data to the form using 'struct'. Argument is like a json hash.
    struct color: :red
    # any data passed to the form distributes to all controls
    # controls can use 'connector' to supply the key to use on the data
    # passed. This works recursively, and it is also possible to
    # use a block, receiving the data and returning the value.
    canvas {
      sizeHint 230
      area [0, 0, 100, 100]
      scale 2
      stroke :none
      circle {
        center 50, 50
        radius 30
        fill {
          # this is the same as color { connector { |data| data.color } }
          color connector: :color
        }
=begin
  Q: since you can say 'fill black' why can't you say 'fill connector: color'?
  A: this has to do with ambiguities that arise. It is unclear that the hash/block passed
     defines a fill or a color. It can be a setup hash/block too.
     Since a color is a primitive it is meaningless of initializing it with a hash or block,
     so we can then know that this is a data-directive instead.

     Compare:
        1)      pen { color: black, weight: 8 }
     with:
        2)      pen { connector: :color }

     I must decide at 'parsetime' if the hash is of version 1 or 2. This would become rather ugly.
     Version 1) creates a Reform::Pen, while version 2) a Reform::DynamicAttribute
=end
      }
    }
  }
}

# hm, and what's the purpose: isn't this just a complicated way of using a a red brush?
#
# ....
#
# see data1_2.rb