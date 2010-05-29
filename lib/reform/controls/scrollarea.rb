
#  Copyright (c) 2010 Eugene Brazwick

module Reform

  # a ScrollArea can contain only 1 widget
  class ScrollArea < Frame
#     def addWidget control, qt_widget = nil
#       tag "addWidget qt_widget=#{qt_widget}",
#       @qtc.widget = qt_widget
#     end

    def addControl control, quickyhash = nil, &block
#       tag "addControl"
      raise 'only one widget!' unless @all_widgets.empty?
      super
      @qtc.widget = control.qtc
    end
  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::ScrollArea, ScrollArea

end # module Reform
