
#  Copyright (c) 2010 Eugene Brazwick

# tag "widget.rb is being read"

module Reform
  require 'reform/control'
  require 'forwardable'

#   class Widget < Control; end
#   class Frame < Widget; end
#   class Layout < Frame; end
#   class BoxLayout < Layout; end
#   class GridLayout < Layout; end

  class Widget < Control
    extend Forwardable

    # qtc of the menu is in fact the qwidget
    class ContextMenuRef < Control
      include ActionContext
      private
#       def initialize widget, qtc
#         super()
#         @widget, @qtc = widget, qtc
#       end

#       def containing_form
#         @widget.containing_form
#       end

      public
      # override to support an array of actions iso of a real hash
        def setupQuickyhash hash
          return unless h0 = hash[0]
          case h0
          when Array then actions(h0)
          when Hash then super(h0)
          else actions(hash)
          end
        end

        def addAction action, hash = nil, &block
  #         tag "#{self} action=#{action}"
          @qtc.contextMenuPolicy = Qt::ActionsContextMenu
          super
        end
    end # class ContextMenuRef

    class FontRef
      private
        def initialize font, hash, &initblock
          @font = font
          instance_eval(&initblock) if initblock
          setupQuickyhash(hash) if hash
        end

        def setupQuickyhash hash
          hash.each { |k, v| send(k, v) }
        end

        def pointSize pt
          @font.pointSize = pt
        end
      public
        attr :font
    end # class FontRef

  private # Widget methods

#     def initialize parent, qtc = nil
#       super
#     end

    # make it the central widget
    def central param = true
      @containing_form.qcentralWidget = @containing_form.qtc.centralWidget = @qtc
    end

    define_simple_setter :locale, :autoFillBackground, :fixedWidth, :acceptDrops

    # if x is integer the size is meant, like fixedSize 200 == fixedSize 200, 200
    # otherwise, if x MUST be 'true' and it sets the policy to :fixed (and 'y' is ignored as well)
    def fixedSize x, y = nil
      if x == true
        self.sizePolicy :fixed
      else
        @qtc.setFixedSize(x, y || x)
      end
    end

    # special values: :base and :dark
    def backgroundRole value = nil
      return @qtc.backgroundRole unless value
      case value
      when :base then value = Qt::Palette::Base
      when :dark then value = Qt::Palette::Dark
      end
      @qtc.backgroundRole = value
    end

    # enforce that parent is a layout
    def check_grid_parent tocheck
      if parent.layout?
        if !parent.is_a?(GridLayout)
          raise ReformError, tr("'#{tocheck}' only works with a gridlayout container!")
        end
      else
        unless layout = parent.infused_layout
  #         tag "Inducing a GridLayout!!!"
          ql = Qt::GridLayout.new
          layout = GridLayout.new(parent, ql)
  #         tag "setting #{parent.qtc}.layout to #{ql}"
          raise 'already a layout!' if parent.qtc.layout
          parent.qtc.layout = ql
          parent.infused_layout = layout
        end
        parent = layout
#         tag "adding widget to layout, waiting for its postSetup"
        layout.addWidget self
      end
    end

    def check_boxparent tocheck
      unless parent.layout? && (Reform::const_defined?(:BoxLayout) && BoxLayout === parent ||
                                Reform::const_defined?(:GridLayout) && GridLayout === parent)
        raise ReformError, tr("'#{tocheck}' only works with a hbox, vbox or gridlayout container!")
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
    # However if f is a hash, or a block is passed we use a FontRef to setup the font.
    # and then assign the result to the widget
    def font f = nil, &block
      return @qtc.font unless f
      if Hash === f || block
#         tag "FontRef trickery!!!!"
        @qtc.font = FontRef.new(@qtc.font, f, &block).font
      else
        @qtc.font = f
      end
    end

    def_delegators :@qtc, :close, :update, :windowTitle=, :height, :width

    def contextMenu *quickyhash, &initblock
      ref = ContextMenuRef.new(self, @qtc)
      ref.setupQuickyhash(quickyhash) if quickyhash
      ref.instance_eval(&initblock) if initblock
    end

    # INCOMPAT change: enabler is now simply 'enabled'. disabler -> disabled
    define_setter TrueClass, :enabled, :disabled
    define_setter FalseClass, :mouseTracking
#     define_setter String, :styleSheet
    define_simple_setter :styleSheet

    WindowFlagMap = { widget: Qt::WidgetType, window: Qt::Window, dialog: Qt::DialogType,
                      popup: Qt::Popup, tool: Qt::Tool, splashscreen: Qt::SplashScreenType,
                      desktop: Qt::Desktop,
                      #, subwindow: Qt::SubwindowType,
                      bypassWM: Qt::X11BypassWindowManagerHint,
                      frameless: Qt::FramelessWindowHint,
                      customize: Qt::CustomizeWindowHint,
                      title: Qt::WindowTitleHint,
                      systemmenu: Qt::WindowSystemMenuHint,
                      minimize: Qt::WindowMinimizeButtonHint,
                      maximize: Qt::WindowMaximizeButtonHint,
                      #minmax: Qt::WindowMinMaxButtonHint,
                      close: Qt::WindowCloseButtonHint,
                      contexthelp: Qt::WindowContextHelpButtonHint,
                      staysOnTop: Qt::WindowStaysOnTopHint,
                      alwaysOnTop: Qt::WindowStaysOnTopHint
    }

    def self.hash2windowFlags f
      pos = neg = 0x0
      for k, v in f
#         tag "k=#{k}"
        if v
          pos |= WindowFlagMap[k].to_i
        else
          neg |= WindowFlagMap[k].to_i
        end
      end
#       tag "pos = #{pos}, neg=#{neg}"
      return pos, neg
    end

    def setWindowFlags flags
      if Hash === flags
        pos, neg = Widget::hash2windowFlags(flags)
        @qtc.windowFlags = (@qtc.windowFlags & ~neg) | pos
      else
        @qtc.windowFlags |= flags
      end
    end

  public # Widget methods

    # override
    def widget?
      true
    end

#     def disabled= val
#       @qtc.enabled = !val
#     end

    def disabled?
      !@qtc.enabled?
    end

    # iso event can also pass painter or QPaintDevice
    # Note that the whenPainted accepts a single painter as argument.
    def whenPainted painter = nil, &block
      if block # is a proc actually
        @whenPainted = block
      else
        return instance_variable_defined?(:@whenPainted) unless painter  # so no args passed at all.
#         return false unless instance_variable_defined?(:@whenPainted)  Caller must check
        rfCallBlockBack(painter, &@whenPainted)
      end
    end #whenPainted

    def whenPainted?
      instance_variable_defined?(:@whenPainted)
    end

    # this only works if the widget is inside a gridlayout
    def span cols = nil, rows = nil
      check_grid_parent :span
      return (instance_variable_defined?(:@span) ? @span : nil) unless cols
      rows ||= 1
      @span = cols, rows
    end

    # assuming you pass it a single arg:
    alias :colspan :span

    # this only works if the widget is inside a gridlayout. Leaving out row or passing nil
    # will make it use the 'current' row.
    # The gridlayout mechanism will automatically jump to the next column.
    # It will respect colspan, and it will jump to the next row if the column is larger
    # than the largest seen up till now, or columnCount (if it is set explicitely)
    # This should be used for exceptional positions, since it is better to specify
    # columnCount within the grid.
    def layoutpos col = nil, row = nil
      check_grid_parent :layoutpos
      return (instance_variable_defined?(:@layoutpos) ? @layoutpos : nil) unless col
      col, row = col if Array === col
      @layoutpos = [col, row || 0]
    end

    # set or title, or setup a special connector
    def windowTitle title_or_hash = nil, &block
      case title_or_hash
      when String then @qtc.windowTitle = title_or_hash
      else
        DynamicAttribute.new(self, :windowTitle, String, title_or_hash, &block)
      end
    end

    alias :title :windowTitle

#     def resize x, y
#       @qtc.resize x, y
#     end

    Sym2SizePolicy = { ignored: Qt::SizePolicy::Ignored,
                       fixed: Qt::SizePolicy::Fixed,
                       minimum: Qt::SizePolicy::Minimum,
                       mamimum: Qt::SizePolicy::Maximum,
                       preferred: Qt::SizePolicy::Preferred,
                       expanding: Qt::SizePolicy::Expanding,
                       minimumExpanding: Qt::SizePolicy::MinimumExpanding
              }

    def sizePolicy x = nil, y = nil
      return @qtc.sizePolicy if x.nil?
      x = Sym2SizePolicy[x] if Symbol === x
      y ||= x
      y = Sym2SizePolicy[y] if Symbol === y
#       tag "#@qtc.setSizePolicy(#{x}, #{y}), ignored==#{Qt::SizePolicy::Ignored}"
      @qtc.setSizePolicy x, y
    end

    # should NOT call qtc.sizeHint, since that's our caller!!!!
    def sizeHint_i
      instance_variable_defined?(:@sizeHint) ? @sizeHint : nil
    end

    def minimumSizeHint_i
      instance_variable_defined?(:@minimumSizeHint) ? @minimumSizeHint : nil
    end

    def sizeHint x = nil, y = nil
      return sizeHint_i || @qtc.sizeHint if x.nil?
      x, y = x if Array === x
      @sizeHint = if Qt::Size === x then x else Qt::Size.new(x, y || x) end
    end

    alias :sizehint :sizeHint

    def minimumSizeHint x = nil, y = nil
      return minimumSizeHint_i || @qtc.minimumSizeHint if x.nil?
      x, y = x if Array === x
      @minimumSizeHint = if Qt::Size === x then x else Qt::Size.new(x, y || x) end
    end

    alias :minimumSize :minimumSizeHint
    alias :minSize :minimumSizeHint
    alias :minimumSizehint :minimumSizeHint

    def_delegators :@qtc, :adjustSize, :enabled?, :style=, :style, :setAttribute

    def resize x, y = nil
      if y.nil?
        @qtc.resize x
      else
        @qtc.resize x, y
      end
    end

    LayoutAlignmentMap = { left: Qt::AlignLeft, right: Qt::AlignRight, center: Qt::AlignCenter }

    def layout_alignment value = nil?
      return @layout_alignment if value.nil?
      value = LayoutAlignmentMap[value] || Qt::AlignLeft if Symbol === value
      @layout_alignment = value
    end

    # this only works if the widget is inside a boxlayout or a gridlayout
    # only in the latter case can you supply a horizontal and vertical value.
    def stretch v = nil, w = nil
      return (instance_variable_defined?(:@stretch) ? @stretch : nil) unless v
      if w
        check_grid_parent 'stretch'
        @stretch = v, w
      else
        check_boxparent 'stretch'
        @stretch = v
      end
    end

    def run
      $qApp.activeWindow = @qtc if self == $qApp.firstform
      @qtc.show
      @qtc.raise
    end # run

#     def self.contextsToUse
#       [ControlContext, App]
#     end

    #override
    def addTo parent, hash, &block
#       tag "#{self}: calling #{parent}.addWidget + SETUP"
      parent.addWidget self, hash, &block
    end

    def addWidget control, hash, &block
#       tag "#{self}.addWidget(#{control.qtc}), qtc = #@qtc"
      control.qtc.parent = @qtc
      control.setup hash, &block
      added control
    end

  # slightly problematic and only for simplistic settings:
    AlignmentMap = { left: Qt::AlignLeft, right: Qt::AlignRight,
                     hcenter: Qt::AlignHCenter, justify: Qt::AlignJustify,
                     top: Qt::AlignTop, bottom: Qt::AlignBottom,
                     vcenter: Qt::AlignVCenter,
                     center: Qt::AlignHCenter | Qt::AlignVCenter,
                     topleft: Qt::AlignLeft | Qt::AlignTop,
                     topright: Qt::AlignRight | Qt::AlignTop,
                     bottomleft: Qt::AlignLeft | Qt::AlignBottom,
                     bottomright: Qt::AlignRight | Qt::AlignBottom
                   }

  end # class Widget

  module QWidgetHackContext
    # override
    def sizeHint
      (instance_variable_defined?(:@_reform_hack) ? (@_reform_hack.sizeHint_i || super) : super) #.tap{|t|tag("#{self}.sz:#{t.inspect}")}
    end

    # override
    def minimumSizeHint
      (instance_variable_defined?(:@_reform_hack) ? (@_reform_hack.minimumSizeHint_i || super) : super) #.tap{|t|tag("#{self}.minszhint:#{t.inspect}")}
    end

#     alias :org_paintEvent :paintEvent         can't do this in a module...

    # it is different for at least QGraphicView
    def paint_target
      self
    end

    # what to if you want both.... And what should be the order? Call qtc.method_missing(:paintEvent, painter.event)
    def paintEvent event
      rfRescue do
  #       tag "paintEvent_i(#{event})"
        if instance_variable_defined?(:@_reform_hack) && @_reform_hack.whenPainted?
  #         tag "Creating Reform::Painter passing #{self}"
          painter = Painter.new(paint_target)
  #         painter.event = event
          begin
            @_reform_hack.whenPainted(painter) != false and return true
            # it is rather inefficient if whenPainted does return false....
          ensure
  #           tag "Calling automatic 'end' after paintEvent"
            painter.end
          end
  #         tag "falling back to default paintEvent handling"
        end
        super
      end
    end

  end # module QWidgetHackContext

  class QWidget < Qt::Widget
#     alias :org_paintEvent :paintEvent         #can't do this in a module...
    include QWidgetHackContext
    public

  end # class QWidget

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

end # Reform