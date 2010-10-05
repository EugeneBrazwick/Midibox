#  Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'frame'

  # Docks can be added only to the mainwindow, but we have currently no context for that...
  class Dock < Frame
    private
      def initialize parent, qtc
        super
        @area = Qt::LeftDockWidgetArea
      end

      define_simple_setter :features

      AreaMap = { left: Qt::LeftDockWidgetArea, right: Qt::RightDockWidgetArea, top: Qt::TopDockWidgetArea,
                  bottom: Qt::BottomDockWidgetArea }

      # can pass a single Qt constant or symbol, or a list of symbols.
      # This is very good idea for more of these bitsets.
      def allowedAreas *values
        if values.length == 1
          v = values[0]
          @qtc.allowedAreas = Symbol === v ? AreaMap[v] : v
        else
          @qtc.allowedAreas = values.inject(0){ |cum, val| cum |= AreaMap[val].to_i }
        end
      end

      def area val
        val = AreaMap[val] || Qt::LeftDockWidgetArea if Symbol === val
        @area = val
      end

      def viewMenu id
        containing_form[id].qtc.addAction(@qtc.toggleViewAction)
      end

      alias :viewmenu :viewMenu

    public

      def addTo parent, hash, &block
        parent.addDockWidget self, @area, hash, &block
      end

      # cannot addWidget, this works similar to mainwindows.
      def addWidget control, hash, &block
        @qtc.widget = control.qtc
        control.setup hash, &block
        added control
      end

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::DockWidget, Dock

end

