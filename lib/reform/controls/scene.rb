
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
    # note that FrameContext is already included in Frame.
    include Graphical, SceneContext
  private
    # set the topleft and size of the scene. These can be floats and
    # can be freely chosen. Zoom, offset and aspectratio can be changed
    # for a specific view (and even rotation etc)
    def area x, y, w, h
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

    # Set the default fill for elements
    def fill brush
      @brush = brush
    end

    # Set the default stroke for elements
    def stroke pen
      @pen = pen
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

    #override
    def addControl control, &block
      qc = if control.respond_to?(:qtc) then control.qtc else control end
      require_relative '../graphicsitem'
      if control.is_a?(GraphicsItem)
        @qtc.addItem(qc)
      else
        @qtc.addWidget(qc)
      end
      super
    end

    # Q: how the hell do we get these in our controls?
    # A: the general rule will be that any graphics item uses containing_frame.brush and
    # containing_frame.pen if it has none defined.
    attr :pen
    attr :brush

    # override. Panel is a widget, but I am not...
    def widget?
    end

  end # class Scene

  createInstantiator :scene, Qt::GraphicsScene, Scene

end # Reform