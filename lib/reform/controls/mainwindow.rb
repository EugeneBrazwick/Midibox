
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'form'

=begin rdoc
 a ReForm is a basic form. It inherits Frame
 but is meant as a complete window.
=end
  class MainWindow < ReForm
    private

    class MenuBarRef < Qt::Object
      # the bar can not contain actions
      include MenuContext
      private
      def initialize mw, qtc
        super()
        @mw, @qtc = mw, qtc
      end

      public
      def setupQuickyhash hash
        hash.each { |k, v| send(k, v) }
      end
    end

    # I noticed this did not work correctly, but this still the case ?
    def menuBar quickyhash = nil, &initblock
      tag "#{self}::menuBar, qtc=#@qtc"
      m = MenuBarRef.new(self, @qtc.menuBar)
      m.setupQuickyhash(quickyhash) if quickyhash
      m.instance_eval(&initblock) if initblock
    end
  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::MainWindow, MainWindow, form: true

end # Reform
