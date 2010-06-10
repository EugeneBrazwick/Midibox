
#  Copyright (c) 2010 Eugene Brazwick

# tag "widget.rb is being read"

module Reform
  require_relative '../control'

  class Widget < Control
  private
    # make it the central widget
    def central param = true
      @containing_form.qcentralWidget = @containing_form.qtc.centralWidget = @qtc
    end

    define_simple_setter :locale

    def check_grid_parent tocheck
      require_relative 'gridlayout' # needed anyway
      if @containing_frame.layout?
        if !@containing_frame.is_a?(GridLayout)
          raise ReformError, tr("'#{tocheck}' only works with a gridlayout container!")
        end
      else
        unless layout = @containing_frame.infused_layout
  #         tag "Inducing a GridLayout!!!"
          ql = Qt::GridLayout.new
          layout = GridLayout.new(@containing_frame, ql)
  #         tag "setting #{@containing_frame.qtc}.layout to #{ql}"
          raise 'already a layout!' if @containing_frame.qtc.layout
          @containing_frame.qtc.layout = ql
          @containing_frame.infused_layout = layout
        end
        @containing_frame = layout
#         tag "adding widget to layout, waiting for its postSetup"
        layout.addWidget self
      end
    end

    def check_boxparent tocheck
      unless @containing_frame.layout? && @containing_frame.is_a?(BoxLayout)
        raise ReformError, tr("'#{tocheck}' only works with a (h/v)box container!")
      end
    end

    # hint for parent layout, do not confuse with 'central'
    def makecenter v = true
#       tag "makecenter called for #{self}"
      check_grid_parent :makecenter
      @layout_alignment = Qt::AlignCenter
    end

    # hint for parent layout
    def rowspan h
      span 1, h
    end

    # assign a font. Possible values ?? some Qt::Font
    def font f = nil
      return @qtc.font unless f
      @qtc.font = f
    end

  public
    # override
    def widget?
      true
    end

    # this only works if the widget is inside a gridlayout
    def span cols = nil, rows = nil
      check_grid_parent :span
      return (instance_variable_defined?(:@span) ? @span : nil) unless cols
      rows ||= 1
#       tag "span := #{rows},#{cols}"
      @span = cols, rows
    end

    # assuming you pass it a single arg:
    alias :colspan :span

    # this only works if the widget is inside a gridlayout. Leaving out row will make it 0
    # which is usefull for defining the first row of widgets. After that the gridlayout
    # will automatically add them one by one in the proper order.
    # This should be used for exceptional positions, since it is better to specify
    # columnCount within the grid.
    def layoutpos col = nil, row = nil
      check_grid_parent :layoutpos
      return (instance_variable_defined?(:@layoutpos) ? @layoutpos : nil) unless col
      @layoutpos = col, row || 0
    end

    define_simple_setter :windowTitle

#     def resize x, y
#       @qtc.resize x, y
#     end

    def sizeHint x = nil, y = nil
      return @qtc.sizeHint if y.nil?
      @qtc.setSizeHint(x, y)  # this hardly works at all
    end

    attr :layout_alignment

    # this only works if the widget is inside a boxlayout
    def stretch v = nil
      return (instance_variable_defined?(:@stretch) ? @stretch : nil) unless v
      check_boxparent 'stretch'
      @stretch = v
    end

#     # ignored
#     def spacing v = nil
#     end

    # this only works if the widget is inside a boxlayout
#     def spacing v = nil
#       return (instance_variable_defined?(:@spacing) ? @spacing : nil) unless v
#       check_boxparent 'spacing'
#       @spacing = v
#     end

    def run
      $qApp.activeWindow = @qtc if self == $qApp.firstform
      @qtc.show
      @qtc.raise
    end # run

    def self.contextsToUse
      [ControlContext, App]
    end

  end # class Widget

  QWidget = Qt::Widget # may change

=begin DESTRUCTION   destroys Qt
  class Qt::Widget

    protected
#     alias :old_resizeEvent :resizeEvent               CANT DO THIS resizeEvent does NOT exist
=begin
    def resizeEvent event
#       old_resizeEvent event
      tag "emit Qt::Widget::resized"
      resized event.size.width, event.size.height
    end
=en d
    public
    signals 'resized(int, int)'
  end
=end

  createInstantiator File.basename(__FILE__, '.rb'), QWidget
end # Reform