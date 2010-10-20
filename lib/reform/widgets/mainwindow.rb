
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'form'

=begin rdoc
 Mainwindows hold a central widget (the first and only one added),
 a menubar, a statusbar, up to 4 docks and several toolbars.

 See Menu and Dock
=end
  class MainWindow < ReForm
    private

      class MenuBarRef < Control
        # the bar can not contain actions, but it can contain a separator
        include MenuContext, ActionContext
        public
        def addMenu control, hash, &block
  #         tag "Calling #@qtc.addMenu(#{control.qtc})"
          @qtc.addMenu control.qtc
          control.setup hash, &block
          added control
        end

      end # MenuBarRef

      class StatusBarRef < Control
        include ControlContext
        private
          def initialize parent, qtc
            super
            @qlabel = nil
          end

          def text value
            unless @qlabel
              @qlabel = Qt::Label.new(@qtc)
              @qtc.addWidget(@qlabel)
            end
            @qlabel.text = value
          end

          def message value, duration = 0
            value, duration = value if Array === value # Oh God....
            duration = duration.value if MilliSeconds == duration
            @qtc.showMessage value, duration
          end
      end

      # can be seen as a menuBar constructor. Within it menus can be defined
      def menuBar quickyhash = nil, &initblock
        return @qtc.menuBar unless quickyhash || initblock
  #       tag "#{self}::menuBar, qtc=#@qtc"
        MenuBarRef.new(self, @qtc.menuBar).setup quickyhash, &initblock
      end

      # can be seen as a statusBar constructor.
      def statusBar quickyhash = nil, &initblock
        return @qtc.statusBar unless quickyhash || initblock
        StatusBarRef.new(self, @qtc.statusBar).setup quickyhash, &initblock
      end

      alias :menubar :menuBar
      alias :statusbar :statusBar

    public

      # :nodoc:
      # this must then be the central widget... No proper checks on this currently
      # however, it should not add the widget. This is done only by a 'central'
      # property or in postSetup.
      def addWidget control, hash, &block
  #       tag "#@qtc.addWidget(#{control.qtc})"
        control.setup hash, &block
        added control
      end

      # :nodoc:
      def addDockWidget dock, area, hash, &block
        # next two lines can be switched. No effect on invisible dock though....
        @qtc.addDockWidget area, dock.qtc
        dock.setup hash, &block
        added dock
      end

      # :nodoc:
      def addToolbar toolbar, hash, &block
        # next two lines can be switched. No effect on invisible dock though....
        @qtc.addToolBar toolbar.qtc
        toolbar.setup hash, &block
        added toolbar
      end

      # :nodoc: override
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
    # make sure we grog resizeEvent (and paintEvent too for that matter)
    include QFormHackContext

  end

  createInstantiator File.basename(__FILE__, '.rb'), QMainWindow, MainWindow, form: true

end # Reform
