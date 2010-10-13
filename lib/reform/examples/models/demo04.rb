
# Copyright (c) 2010 Eugene Brazwick

=begin
This example uses a hash for the internal model of a combobox.
The tricky thing is that the Qt model works with rows and columns
and these are both integers.

Each hashvalue becomes a row in the table, and currently index-lookup is
performed through linear search.  Could become a cached index later.

The problem is that ruby has no way of retrieving a hash value through the
sequential index. You must build an internal array for keys or use each_pair.to_ary
or something like that.  Also alterations of the hash (even through an abort)
will invalidate the index so it's not as easy it sounds.

Anyway the connector is still self, so we find :blue and then we use key2index
This is different for hashes than for arrays. The connector should result in the key.
Similar if the value changes the key is used as the new value.

=end

require 'reform/app'

Reform::app {
  form {
    struct :blue
    combo {
      struct red: 'hot', blue: 'cold', green: 'OK', magenta: 'pretty',
             darkBlue: 'watery', white: 'pure', black: 'evil'
      connector :self
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