#!/usr/bin/ruby1.9.1
# $Id: extruby.rb,v 1.4 2010/02/19 22:04:44 ara Exp $
require 'mkmf'
dir_config 'alsa_midi'
have_library 'asound', 'snd_seq_open'
create_makefile 'alsa_midi'

# RECEPY:
#  ruby ./extruby.rb
#  make
