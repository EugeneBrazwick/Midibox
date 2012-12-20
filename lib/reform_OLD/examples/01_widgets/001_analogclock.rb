#!/usr/bin/ruby

# Copyright (c) 2011 Eugene Brazwick

# Reform programs are 100% pure ruby. If RUBYLIB is set
# to include Midibox/lib then it should run straight out of 
# the box, provided the required gems are installed.
# There is a wrapper 'reform.bash' in Midibox/bin that sets
# and checks everything automatically, so you can run:

#		/<some_path>/Midibox/bin/reform.bash ./001.analogclock.rb

# I put this in my ~/.bashrc:

#		alias reform=~/Midibox/bin/reform.bash

# So I can do this:

# 		reform ./001*

# Now the structure of this first reform program:
# The first step is to load the 'Application' class definition:
require 'reform/app'

# The second step is to construct the application like this:
Reform::app {
  # this is an extremely dirty trick...
  # tomorrow I'll show how to implement it using a generic Widget!
  # Finally you can put components in the application.
  # Reform will look in lib/reform/widgets/ for widget plugins,
  # and also in lib/reform/contrib/widgets/
  # To instantiate the plugin use the filename minus the extension
  # Since lib/reform/contrib/widgets/analogclock.rb exists
  # we can instantiate it like this:
  analogclock
}

