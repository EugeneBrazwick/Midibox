
module Reform

  require_relative 'frame'

=begin  It should be noted that Qt has Qt::GraphicsProxyWidget which enables ALL
        (or a lot) of Qt::Widget to be added to a scene!!
Example

     QApplication app(argc, argv);

     QTabWidget *tabWidget = new QTabWidget;

     QGraphicsScene scene;
     QGraphicsProxyWidget *proxy = scene.addWidget(tabWidget);

     QGraphicsView view(&scene);
     view.show();

     return app.exec();

Even more, a QDialog can be stored in the view as well!
=end
=begin rdoc
  A Scene is a panel where all normal form controls can be stored in, but
  in addition we support graphical items, shapes, and animations too.
=end
  class Scene < Frame
    require 'reform/graphical'
    # note that ControlContext is already included in Frame.
    include Graphical, GraphicContext, AnimationContext, StateContext

  private # Scene Methods

    def initialize parent, qtc
      super
      @pen = defaultPen
      @brush = defaultBrush
    end

    # same as area 0, 0, w, h
    def size w, h = w
      @qtc.setSceneRect 0, 0, w, h
    end

    def indexMethod m
      @qtc.itemIndexMethod = m
    end

=begin
    specific for scenes. This is a matrix operator. You can specify
    rotate, translate, scale, fillhue and strokehue currently.
    All other components added to the duplicate (which is a Scene)
    are added to the parent instead, after which the transformation is
    applied and we repeat the addition.
    When done the original scene parameters are restored.
    The number of times to do this is set by 'count'. If 'count' is
    not set, then 'rotate' must be set to > zero and it will be applied
    until we arrive at 1.0 or 360 (float or int param).
=end
#     def duplicate &block
#     end  AARGH

  public # Scene methods

#     def registerGroupMacro name, group
#       @groups[name] = group
#     end

    # set the topleft and size of the scene. These can be floats and
    # can be freely chosen. Zoom, offset and aspectratio can be changed
    # for a specific view (and even rotation etc)
    def area x = nil, y = nil, w = nil, h = nil
      return @qtc.sceneRect unless x
      x, y, w, h = x if Array === x && y.nil?
#       tag "sceneRect := #{x}, #{y}, #{w}x#{h}"
      @qtc.setSceneRect x, y, w, h || w
    end

    def area= rect
      @qtc.sceneRect = rect
    end

    # Set the default fill for elements.
    def fill *args, &block
      return @brush unless !args.empty? || block
#       tag "assigning brush, oldbrush = #@brush"
      @brush = make_qtbrush_with_parent(self, *args, &block)
#       tag "assigned effective brush #@brush"
      children.each do |child|
        child.qtbrush = @brush if GraphicsItem === child && !child.explicit_brush
      end
    end

    # Set the default stroke for elements
    def stroke *args, &block
      return @pen unless !args.empty? || block
#       tag "stroke := ... "
      self.qtpen = make_qtpen_with_parent(self, *args, &block)
    end

    def qtpen= pen
#       tag "#{self}.qtpen := #{pen}, color=#{pen.color.inspect}"
      @pen = pen # ???? was missing
      children.each do |child|
        if GraphicsItem === child && !child.explicit_pen
#           tag "CALLING #{child}.qtpen := #{@pen.inspect}"
          child.qtpen = pen
        end
      end
    end

    def qtbrush= brush
      @brush = brush
      children.each do |child|
        child.qtbrush = brus if GraphicsItem === child && !child.explicit_brush
      end
    end

    alias :brush :fill
    alias :pen :stroke

    def background *args, &block
#       tag "Scene#background #{args.inspect}"
      return @qtc.backgroundBrush unless args[0] || block
#         tag "args[0].class = #{args[0].class}"
      @qtc.backgroundBrush = case args[0]
        when Symbol then containing_form.registeredBrush(args[0]) || make_qtbrush_with_parent(self, *args)
        when Qt::Brush then args[0]
        when nil #DynamicAttribute.new(self, :brush, Qt::Brush, nil, &block).value
          Brush.new(self, :backgroundBrush=).setup(&block).qtc # .tap{|t| tag "brush.qtc=#{t}"}
        when Hash
          args[0][:dynname] = :backgroundBrush=
          make_qtbrush_with_parent(self, *args)
        else
          make_qtbrush_with_parent(self, *args)
        end
    end

    def font *args, &block
      return @font unless !args.empty? || block
#       tag "#{self}#font(#{args.inspect})"
      self.qtfont = make_qtfont_with_parent(self, *args, &block)
    end

    def qtfont= f
      @font = f
      children.each do |child|
        if GraphicsItem === child && !child.explicit_font
#           tag "assigning qtfont #{@font.family} to child #{child}"
          child.qtfont = @font
        end
      end
    end

  #override
    def addGraphicsItem control, quickyhash = nil, &block
#       tag "#{self}.addGraphicsItem, control #{control} is added to SCENE, brush=#@brush, font = #{@font.inspect}"
#       qc = if control.respond_to?(:qtc) then control.qtc else control end             BOGO we call 'setup' two lines ahead anyway!
      @qtc.addItem control.qtc
#       tag "#{control}.parent := #{self}"
      control.parent = self
      control.qtpen, control.qtbrush = @pen, @brush  # initial implict tools
#       tag "setting pen #{@pen} color: #{@pen.color.inspect} in control #{control}"
      control.qtfont = @font
      control.setup quickyhash, &block
      added control
#       tag "#{control}.parent is now #{control.parent}, ctrl.brush = #{control.brush}"
#       when Timer, Qt::Timer #then tag "start timer"; qc.start(1000)
#       else @qtc.addWidget(qc)
#       end
#       super
    end

    def parent_qtc_to_use_for reform_class
    end

    # override. Panel is a widget, but I am not...
    def widget?
    end

    def_delegators :@qtc, :clear, :backgroundBrush=

        #override
    def addTo parent, hash, &block
      parent.addScene(self, hash, &block)
    end

  end # class Scene

  createInstantiator :scene, Qt::GraphicsScene, Scene

end # Reform