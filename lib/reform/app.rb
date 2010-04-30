
require 'Qt'

# for debugging purposes only
# if $DEBUG             would be neat if qtruby did not 1_000_000 warnings....
  module Kernel
    def tag msg
      # avoid puts for threading problems
      STDERR.print "#{caller[0]} #{msg}\n"
    end
  end
# end

=begin  rdoc
The Reform library is a qtruby based library for building gui's in a 100%
declarative way (we do not compromise!!!)
There are NO methods involved. Ever. Anywhere.

Requirements:
=========================================================
  - qt4.6
  - kdebindings_4.4.2
  - ruby1.9.1

Recepy for Ubuntu (of the Blood Sweat and Tears Kind -- but in the end it was 'simply' this:)

Preliminaries:
  I hacked my ruby install on ubuntu (since 1.9.1 works fine and should be the default!),
  with a bunch of links:
  - cd /usr/bin
  - sudo ln -s {erb,rake,ruby,irb,rdoc,ri}1.9.1 .
  - cd /usr/lib
  - sudo ln -s libruby-1.9.1.so libruby-1.9.so
  - cd /usr/include/ruby-1.9.1/ruby
  - sudo ln -s ../x86_64-linux/ruby/config.h
  - sudo apt-get install ????  # Hm... I installed kde-devel and smoke-dev-tools and
      God knows what more. These may be required but I do not yet know this. Need to built
      vm for this.

  - download source from ubuntu (lucid)
  - tar zxf tarballs/kdebindings_4.4.2.orig.tar.gz
  - gunzip tarballs/kdebindings_4.4.2-0ubuntu2.diff.gz
  - patch < tarballs/kdebindings_4.4.2-0ubuntu2.diff
  - cd kdebindings-4.4.2/
  - cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DRUBY_EXECUTABLE=/usr/bin/ruby \
      -DRUBY_INCLUDE_PATH=/usr/include/ruby-1.9.1 \
      -DRUBY_LIBRARY=/usr/lib/libruby-1.9.so \
      -DENABLE_QIMAGEBLITZ_SMOKE=off -DENABLE_ATTICA_SMOKE=off -DENABLE_KROSSRUBY=off -Wno-dev
  - make
  - sudo make install

Note: it builds far too much... So takes an hour. Feel free to skip more by disabling more
    modules. For your convenience:
      -DENABLE_QTWEBKIT_SMOKE=off -DENABLE_QTSCRIPT_SMOKE=off \
      -DENABLE_QTUITOOLS_SMOKE=off -DENABLE_QTTEST_SMOKE=off -DENABLE_PHONON_SMOKE=off  \
      -DENABLE_QSCI_SMOKE=off -DENABLE_QWT_SMOKE=off -DENABLE_KDE_SMOKE=off \
      -DENABLE_KDEVPLATFORM_SMOKE=off -DENABLE_KHTML_SMOKE=off -DENABLE_KTEXTEDITOR_SMOKE=off \
      -DENABLE_SOLID_SMOKE=off -DENABLE_PLASMA_SMOKE=off -DENABLE_QTWEBKIT_RUBY=off \
      -DENABLE_QTUITOOLS_RUBY=off -DENABLE_QTSCRIPT=off  -DENABLE_QTTEST=off -DENABLE_PHONON_RUBY=off \
      -DENABLE_QSCINTILLA_RUBY=off -DENABLE_QWT_RUBY=off -DENABLE_SOPRANO_RUBY=off  \
      -DENABLE_KDEVPLATFORM_RUBY=off -DENABLE_KORUNDUM_RUBY=off -DENABLE_KHTML_RUBY=off \
      -DENABLE_KTEXTEDITOR_RUBY=off -DENABLE_SOLID_RUBY=off -DENABLE_PLASMA_RUBY=off \

However, this is uncharted territory. The modules I disabled had to be disabled because the
compile failed.

About qt4-qtruby.  This package is for ruby1.8. You can download the source and compile it for
ruby1.9.1 but it will never work (it did for karmic though).
qtruby is now officially part of kdebindings, I guess.

CONCEPTS
========================================

Shoes (as in 'stolen from')

But 'shoes' is too much a toy.

The idea is to map a datastructure one-on-one on a form. By picking the controls
you can make any view for a model.

Richard Dale has made two qtruby modelsystems that can be used for ActiveRecord and
ActiveResource.
I would like to add one for Object. Or even BasicObject. Because any ruby instance is
obviously a model.

=end
module Reform
  private

=begin rdoc
  the App is a basic Qt::Application extension. So see the qt docs as well.
  I use 'exec' from Reform::app
=end
  class App < Qt::Application
      private

=begin rdoc
the application constructor is passed the commandline. Or any splat for that matter.
The idea is that it is a singleton.
=end
    def initialize *argv
      super
      # firstform points to the first form defined, which is the main form (mainwindow)
      @firstform = nil
      # forms is the list of all named forms (and only 'named' forms)
      @forms = {}
      # title is used as caption
      @title = nil
    end

    public
    # override called from Reform::app
    def exec
#       tag "exec"
      # without any forms it loops, waiting until we quit.
      @firstform.run if @firstform
  #     puts "activeWindow = #{activeWindow.inspect}"
      unless activeWindow
        # I was tempted to put 'Hallo World' in this place:
        hello = Qt::PushButton::new tr('It Just Works')
        geometry = desktop.screenGeometry
        size = geometry.size / 2
        # ugly: qsize not excepted by moveTopLeft !!!
        topleft = Qt::Point.new(size.width, size.height)
        geometry.size = size
        geometry.moveTopLeft topleft / 2
        hello.geometry = geometry
        hello.show
      end
      super
    end

  end # class App

  # create an application, passing ARGV to it, then run it
  # Any block passed is executed in the constructor redirecting self to $qApp.
  def self.app &block
    App.new ARGV
    # extend the Form class with the proper contributed widgets
    for file in Dir[File.dirname(__FILE__) + '/controls/*.rb']
      registerControlClassProxy File.basename(file, '.rb'), 'controls/' + file
    end
    for file in Dir[File.dirname(__FILE__) + '/contrib_widgets/*.rb']
      registerControlClassProxy File.basename(file, '.rb'), 'contrib_widgets/' + file
    end
  #IMPORTANT, if any of the files loaded by these instantiators does not redefine the
  # instantiator this will cause a stack failure since we keep loading for ever...
    require_relative 'graphics'         # Scene must be known, Panel already is
    for file in Dir[File.dirname(__FILE__) + '/graphics/*.rb']
      registerGraphicsControlClassProxy File.basename(file, '.rb'), 'graphics/' + file
    end
#     puts "#{File.basename(__FILE__)}:#{__LINE__}: registered proxies"
    $qApp.instance_eval(&block) if block
    $qApp.exec
  end
end

if __FILE__ == $0
  Reform::app
end