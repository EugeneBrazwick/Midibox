
# Copyright (c) 2013 Eugene Brazwick

# This example uses plug-n-play techno to get the effect of the
# colorlisteditor.

require 'reform/app'

# pull in Qt::Color:
require 'reform/graphicsitem'

=begin

We need to think about storage here.

Normally the store a table we use an array.
Like Employees.

  Employees = [Employee.new(key: 1, name: 'Richard', age: 24),
	       Employee.new(key: 2, name: 'Linda', age: 34)
	       ...
	      ]

a selected item should then propagate as is. So as Employee.      

so:
    linda = Employees.find { |e| e.key == 2 }
    data linda

But the only way to find the record in the array is as we know that 'key'
is in fact the 'key'.

    combo {
      data Employees
      connector :self
      local_connector :name
    }

To locate linda in the local data we simply do a linear search.
We display all names.
If the user picks a record, the outer 'data' is updated with the record.

Now a hash.

  combo {
    data Employees.reduce({}) { |h, e| h[e.key] = e; h }
    connector :self
    local_connector :name
  }

If we now connect something with a 'key' we locate that key in the hash and
select that row. Much faster than for an array.

So for our example, Qt::Color simply needs a 'key' method that returns a proper hashkey.
By default 'key' may return 'hash', which is set in Object.  But 'hash' need not be unique,
where 'key' should. 
It is also possible to use object_id. But that may change over persistent calls, so 
questionable. Even more, we have 'yes'.object_id != 'yes'.object_id, so as a key
it is pretty worthless.

=end

# include R so R::Qt becomes Qt
include R
Reform::app {
  fail_on_errors true
  data 'white'
  frame {
    contentsMargins 4
    shadow :sunken
    shape :styled_panel
    # storing a widget inside a frame creates a layout implicitely
    combo {
      # declare local data:
      data Qt::Color::colorNames.reduce({}) { |hash, el| hash[el] = Qt::Color.new(el); hash }

      connector :self

      # how to get key from global data:
      key :self 
      # that also tells it what to store back into the model (if :self special case)
      
      # we want to display the 'key' of the colornamehash:
      display :key    # so it shows the names. This is a 'pseudo-cid' like :self and :value

      # deco refers to a color, brush or image
      decoration :self   # and deco is stuck to the actual color
    }
    # our edit shows the colorname, so we can see it change
    edit connector: :self
  }
}

