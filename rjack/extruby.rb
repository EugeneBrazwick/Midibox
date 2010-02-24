#!/usr/bin/ruby1.9
# $Id: extruby.rb,v 1.3 2009/06/25 19:54:38 ara Exp $
require 'mkmf'
dir_config 'jack'
have_library 'jack', 'jack_client_open'
create_makefile 'rjack'

# RECEPY:
#  ./extruby.rb
#  make
