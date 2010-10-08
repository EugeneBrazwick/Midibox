
#  Copyright (c) 2010 Eugene Brazwick

module Reform

  # a ScrollArea can contain only 1 widget
  class ScrollArea < Frame

    def addWidget control, quickyhash = nil, &block
#       tag "ScrollArea::addControl, calling widget := ..."
      raise 'only one widget!' if @qtc.widget
      super
      @qtc.widget = control.qtc
    end

    def horizontalScrollBar
      @qtc.horizontalScrollBar
    end

    def verticalScrollBar
      @qtc.verticalScrollBar
    end

    def widgetResizable= value
      @qtc.widgetResizable = value
    end
  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::ScrollArea, ScrollArea

end # module Reform
