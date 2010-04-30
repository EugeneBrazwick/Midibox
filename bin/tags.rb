
# Copyright (c) 2010 Eugene Brazwick

=begin

Program: tags.rb

Parameters:
      --system, alter the system tags.  During development that would be ../data/tagdb.yaml
          When installed it should be $PREFIX/share/rrts/tagdb.yaml
      --data=path.  Like '../data/tagdb.yaml' Path of systemdb only.

If system is not set you can alter ~/.rrtsrc/tagdb.yaml only and this path is fixed.
Note however that '~' is not understood by ruby. ENV['HOME'] should be used.
=end

# include the application:
require_relative '../lib/reform/app'

# create the default application:
Reform::app

__END__

Tags are used as glue.
Difference with ordinary tags: they carry a weight (where 1.0 is the average).
Tags can be linked to
    - voices
    - styles
    - musical terms indicating mood and speed. Like andante.
    - tags, but not circular.
Because they decide how random elements are picked this is very much a personal
issue.
Tags come therefore in two databases. One shared, the systemprovided tagdb. And one
personal stored in ~/.rrtsrc
Tags can be freely added, altered and even deleted, without altering the
system default.

This program takes care of that.
