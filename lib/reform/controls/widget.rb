
#  Copyright (c) 2010 Eugene Brazwick

# tag "widget.rb is being read"

module Reform
  require_relative '../control'

  class Widget < Control
  private

    def close
      @qtc.close
    end

    # make it the central widget
    def central param = true
      @containing_form.qcentralWidget = @containing_form.qtc.centralWidget = @qtc
    end

    define_simple_setter :locale, :autoFillBackground

    def fixedSize x, y = nil
      @qtc.setFixedSize(x, y || x)
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

    def check_grid_parent tocheck
      require_relative 'gridlayout' # needed anyway
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
      unless parent.layout? && parent.is_a?(BoxLayout)
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

    def contextMenu *quickyhash, &initblock
      ref = ContextMenuRef.new(self, @qtc)
      ref.setupQuickyhash(quickyhash) if quickyhash
      ref.instance_eval(&initblock) if initblock
    end

    def enabler value = nil, &block
      return instance_variable_defined?(:@enabler) && @enabler if value.nil? && !block
      @enabler = block ? block : value
    end

    def disabler value = nil, &block
      return instance_variable_defined?(:@disabler) && @disabler if value.nil? && !block
      @disabler = block ? block : value
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
      instance_variable_get(:@sizeHint) ? @sizeHint : nil
    end

    def sizeHint x = nil, y = nil
      return sizeHint_i || @qtc.sizeHint if x.nil?
      @sizeHint = if y.nil? then x else Qt::Size.new(x, y) end # this currently only works for forms!!! Not other windows!!!
#       @qtc.setSizeHint(x, y)  # this hardly works at all. Note there is a virtual method: QWidget 'sizeHint()'!!
    end

    alias :sizehint :sizeHint

    def adjustSize
#       tag "calling #@qtc.adjustSize"
      @qtc.adjustSize
    end

    def resize x, y = nil
      if y.nil?
        @qtc.resize x
      else
        @qtc.resize x, y
      end
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

    #override
    def addTo parent, hash, &block
#       tag "#{self}: calling #{parent}.addWidget + SETUP"
      parent.addWidget self, hash, &block
    end

    def updateModel model, options = nil
      if (e = enabler) && model.getter?(e)
        @qtc.enabled = model.apply_getter(e)
      end
      if (d = disabler) && model.getter?(d)
        @qtc.enabled = !model.apply_getter(d)
      end
      super
    end

    def addWidget control, hash, &block
      control.qtc.parent = @qtc
      control.setup hash, &block
      added control
    end

  end # class Widget

  class QWidget < Qt::Widget
    public
    # override
    def sizeHint
      instance_variable_get(:@_reform_hack) ? (@_reform_hack.sizeHint_i || super) : super
    end
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

  createInstantiator File.basename(__FILE__, '.rb'), QWidget
end # Reform