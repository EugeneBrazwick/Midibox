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

    define_simple_setter :features, :allowedAreas

    AreaMap = { left: Qt::LeftDockWidgetArea, right: Qt::RightDockWidgetArea, top: Qt::TopDockWidgetArea,
                bottom: Qt::BottomDockWidgetArea }

    def area val
      val = AreaMap[val] || Qt::LeftDockWidgetArea if Symbol === val
      @area = val
    end

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

