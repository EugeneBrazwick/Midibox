
module Reform
  require_relative 'control'

  class Widget < Control
  private
    # make it the central widget
    def central
      @owner.qcentralWidget = @owner.qtc.centralWidget = @qtc
    end

    define_simple_setter :locale

    def check_grid_parent tocheck
      require_relative 'controls/gridlayout' # needed anyway
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

    # hint for parent layout
    def makecenter
#       tag "makecenter called for #{self}"
      check_grid_parent :makecenter
      @layout_alignment = Qt::AlignCenter
    end

    # hint for parent layout
    def colspan w
      span 1, w
    end

    # hint for parent layout
    def rowspan h
      span h, 1
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
    def span rows = nil, cols = nil
      check_grid_parent :span
      return (instance_variable_defined?(:@span) ? @span : nil) unless rows
      cols ||= rows
#       tag "span := #{rows},#{cols}"
      @span = rows, cols
    end

    # this only works if the widget is inside a gridlayout
    def layoutpos row = nil, col = nil
      check_grid_parent :layoutpos
      return (instance_variable_defined?(:@layoutpos) ? @layoutpos : nil) unless row
      @layoutpos = row, col
    end

    define_simple_setter :windowTitle

    def sizeHint x = nil, y = nil
      return @qtc.sizeHint if y.nil?
      @qtc.setSizeHint(x, y)
    end

    attr :layout_alignment

  end # class Widget

  QWidget = Qt::Widget # may change
end # Reform