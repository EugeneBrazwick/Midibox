
# Copyright (c) 2010 Eugene Brazwick

require 'reform/app'

# This nice thing is this uses the actual array to get the data from.
# I don't know how these items are wrapped internally but it seems better than using
# stringlists.
Reform::app {
  list struct: %w[the cat wasn't at home that day]
}