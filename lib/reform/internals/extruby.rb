#!/usr/bin/ruby
require 'mkmf'
dir_config 'reform_internals'
have_library 'QtCore', '_ZN8QVariantC1ER11QDataStream'
find_header 'QtCore/qstack.h', '/usr/include/qt4', '/usr/local/include/qt4', '/opt/qt4/include'
# I did my best.... mkmf is CRAP CODE!! But no less than the following hardcoded shit:
$INCFLAGS << " -I/usr/include/qt4"
create_makefile 'reform_internals'

# RECEPY:
#  ruby ./extruby.rb
#  make
