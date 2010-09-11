
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'form'

=begin rdoc
 a ReForm is a basic form. It inherits Frame
 but is meant as a complete window.

 Mainwindows hold a central widget (the first added),
 a menubar, a statusbar, up to 4 docks and several toolbars.
=end
  class MainWindow < ReForm
    private

    class MenuBarRef < Control
      # the bar can not contain actions, but it can contain a separator
      include MenuContext, ActionContext
      private
#       def initialize mw, qtc
#         super()
#         @mw, @qtc = mw, qtc
#       end

      public

      def addMenu control, hash, &block
#         tag "Calling #@qtc.addMenu(#{control.qtc})"
        @qtc.addMenu control.qtc
        control.setup hash, &block
        added control
      end

    end # MenuBarRef

    class StatusBarRef < Control
    end

    # I noticed this did not work correctly, but this still the case ?
    def menuBar quickyhash = nil, &initblock
#       tag "#{self}::menuBar, qtc=#@qtc"
#       m = MenuBarRef.new(self, @qtc.menuBar)
#       m.setupQuickyhash(quickyhash) if quickyhash
#       m.instance_eval(&initblock) if initblock
      MenuBarRef.new(self, @qtc.menuBar).setup quickyhash, &initblock
    end

    def statusBar quickyhash = nil, &initblock
      StatusBarRef.new(self, @qtc.statusBar).setup quickyhash, &initblock
    end

    alias :menubar :menuBar
    alias :statusbar :statusBar

    public

    # this must then be the central widget... No proper checks on this currently
    # however, it should not add the widget. This is done only by a 'central'
    # property or in postSetup.
    def addWidget control, hash, &block
#       tag "#@qtc.addWidget(#{control.qtc})"
      control.setup hash, &block
      added control
    end

    def addDockWidget dock, area, hash, &block
      # next two lines can be switched. No effect on invisible dock though....
      @qtc.addDockWidget area, dock.qtc
      dock.setup hash, &block
      added dock
    end

    def postSetup
      super
      unless @qtc.centralWidget
        suitable = children.find {|c| c.widget? }
        ctrl = suitable || button(text: tr('It Just Works!'))
        ctrl = ctrl.qtc if ctrl.respond_to?(:qtc)
#         tag "setting centralWidget to #{ctrl}"
        @qtc.centralWidget = ctrl
      end
    end

  end

  class QMainWindow < Qt::MainWindow
  private
#     def initialize
#       super
#       tag "new QMainWindow, size=#{size.inspect}"
#       resize 500, 400         does not help at all
#     end

  public
    # override, almost same as QWindow's version
    def sizeHint
      @_reform_hack.sizeHint
    end
  end

  createInstantiator File.basename(__FILE__, '.rb'), QMainWindow, MainWindow, form: true

end # Reform
