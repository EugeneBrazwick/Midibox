#!/usr/bin/ruby1.9
#$Id: main.rb,v 1.2 2009/07/28 13:23:03 ara Exp $

=begin
ln -s ruby1.9/include/ruby-1.9.1/i686-linux/ruby/config.h ruby1.9/include/ruby-1.9.1/ruby/config.h

and

cd /media/work/qt4-qtruby-2.0.3/
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/ -DRUBY_EXECUTABLE=/usr/bin/ruby1.9 \
      -DRUBY_LIBRARY=/usr/lib/libruby1.9.so -DRUBY_INCLUDE_PATH=/usr/include/ruby-1.9.1/ \
      -DENABLE_SMOKEKDE=off -DENABLE_QYOTO=off -DENABLE_PYKDE4=off -DENABLE_KROSSRUBY=off -Wno-dev

Note:after installing 1.9.1 from source the binary and libs can be used without a versionsuffix.

Some tools:

  rbqtapi -s Qt::Application
  shows all methods in Application.               -s :show ruby types
                                                  -p: display ALL methods
                                                  -m <regexp>: matching ....
  rbrcc -o <file> <inputs>

Example rbrcc -o example7_rc.rb example7.qrc

=end

require 'Qt'

application = Qt::Application.new ARGV
window = Qt::Widget.new
window.resize 320, 240
window.show
application.exec
