
module Reform

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
  class Scene < Panel
    require_relative 'graphical'
    include Graphical
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

    # this is clearly procedural!
#     def fill brush
#       GraphicsItem.default_brush = brush
#     end
#
#     def stroke pen
#       GraphicItem.default_pen = pen
#     end

  public

    def self.define_color name, col
      define_method(name) do
#         puts "#{File.basename(__FILE__)}:#{__LINE__}:new Qt::Brush(#{name})"
        Qt::Brush.new(col)
      end
    end

    #override
    def addControl control, &block
#       puts "#{File.basename(__FILE__)}:#{__LINE__}: Scene#addControl(#{control}"
      qc = if control.respond_to?(:qtc) then control.qtc else control end
#       raise 'kuch' unless qc.inherits('QGraphicsItem')
#       puts "#{File.basename(__FILE__)}:#{__LINE__}: adding item #{qc} to #@qtc"
      if GraphicsItem === control
        @qtc.addItem(qc)
      else
        @qtc.addWidget(qc)
      end
      super
    end

    # override. Panel is a widget, but I am not...
    def widget?
    end

  end # class Scene

  createInstantiator :scene, Qt::GraphicsScene, Scene

end # Reform