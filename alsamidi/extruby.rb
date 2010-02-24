#!/usr/bin/ruby1.9.1
require 'mkmf'
dir_config 'alsa_midi'
have_library 'asound', 'snd_seq_open'
create_makefile 'alsa_midi'

# RECEPY:
#  ruby ./extruby.rb
#  make
