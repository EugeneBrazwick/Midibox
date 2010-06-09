
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
    require_relative '../graphical'
    # note that ControlContext is already included in Frame.
    include Graphical, GraphicContext
  private
    # set the topleft and size of the scene. These can be floats and
    # can be freely chosen. Zoom, offset and aspectratio can be changed
    # for a specific view (and even rotation etc)
    def area x, y, w, h
#       tag "sceneRect := #{x}, #{y}, #{w}x#{h}"
      @qtc.setSceneRect x, y, w, h
    end

    # same as area 0, 0, w, h
    def size w, h
      @qtc.setSceneRect 0, 0, w, h
    end

    def indexMethod m
      @qtc.itemIndexMethod = m
    end

    def background brush
      if brush.respond_to?(:to_str)
        # load the image, where the path is given.
        brush = Qt::Brush.new(Qt::Pixmap.new(brush))
      end
#       puts "#{File.basename(__FILE__)}:#{__LINE__}:#@qtc.backgroundBrush := #{brush}"
      @qtc.backgroundBrush = brush
    end

=begin rdoc
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

  public

    # Set the default fill for elements.
    def fill brush = nil
      return (@brush || defaultBrush) unless brush
      case brush
      when Qt::Brush
        @brush = brush
      else
        @brush = color2brush(brush)
      end
    end


    # Set the default stroke for elements
    def stroke pen = nil
      return (@pen || defaultPen) unless pen
      case pen
      when Qt::Pen
        @pen = pen
      else
        @pen = color2pen(pen)
      end
    end

    alias :brush :fill
    alias :pen :stroke

  #override
    def addControl control, quickyhash = nil, &block
#       tag "addControl, control #{control} is added to SCENE"
      qc = if control.respond_to?(:qtc) then control.qtc else control end
      require_relative '../graphicsitem'
      case control
      when GraphicsItem then @qtc.addItem(qc)
      when Timer, Qt::Timer #then tag "start timer"; qc.start(1000)
      else @qtc.addWidget(qc)
      end
      super
    end

    # override. Panel is a widget, but I am not...
    def widget?
    end

  end # class Scene

  createInstantiator :scene, Qt::GraphicsScene, Scene

end # Reform