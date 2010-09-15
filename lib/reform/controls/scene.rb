
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

    def initialize parent, qtc
      super
      @brushes = {} # indexed by name
      @groups = {} # ""
      @pen = defaultPen
      @brush = defaultBrush
    end

    # set the topleft and size of the scene. These can be floats and
    # can be freely chosen. Zoom, offset and aspectratio can be changed
    # for a specific view (and even rotation etc)
    def area x, y, w, h = w
#       tag "sceneRect := #{x}, #{y}, #{w}x#{h}"
      @qtc.setSceneRect x, y, w, h
    end

    # same as area 0, 0, w, h
    def size w, h = w
      @qtc.setSceneRect 0, 0, w, h
    end

    def indexMethod m
      @qtc.itemIndexMethod = m
    end

    def background brush
      @qtc.backgroundBrush = make_brush(brush)
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

    class Brush < Control
      include Graphical
    private
      def initialize
        super(nil, Qt::Brush.new)
      end

    public
      def name aName = nil # not supported since not a Qt::Object at all. And we already index them too
      end

    end # class Brush

    class Pen < Control
      include Graphical
      def initialize
        super(nil, Qt::Pen.new)
      end

    public
      def name aName = nil
      end
    end # class Pen

      # you can build a brush, pen and graphicitem pool.
      class DefinitionsBlock < Control
        include Graphical

        private

          class GroupMacro < Control
            include Graphical, SceneFrameMacroContext
            private
              def initialize hash, &initblock
                super(nil)
                instance_eval(&initblock) if initblock
                hash.each { |k, v| send(k, v) } if hash
              end

            public
              def exec receiver, quicky, &block
                tag "FIXME, ignoring quicky + block" # should be working on the group.
      #           receiver.setup ???
                executeMacros(receiver)
              end

          end # GroupMacro

            # I see a pattern here (FIXME)
          def brush quickyhash = nil, &block
    #         tag "Is this even called??"
            Brush.new.setup(quickyhash, &block)
          end

          alias :fill :brush

          def pen quickyhash = nil, &block
            Pen.new.setup(quickyhash, &block)
          end

          alias :stroke :pen

          def shapegroup quickyhash = nil, &block
            GroupMacro.new(quickyhash, &block)
          end

        public

          def method_missing sym, *args, &block
            if args.length == 1 && !block
    #           tag "single arg: #{self}.#{sym}(#{args[0]})"
              case what = args[0]
              when Brush, Gradient then parent.registerBrush(sym, what)
              when Pen then parent.registerPen(sym, what)
                # parent is always the scene
              when GroupMacro then Graphical.registerGroupMacro(parent, sym, what)
              else super
              end
            else
              super
            end
          end

  #       def updateModel model, info
          # IGNORE, at least currently. It may be usefull to create dynamic tools.... So never mind....
  #       end
      end # class DefinitionsBlock

    def define quickyhash = nil, &block
      DefinitionsBlock.new(self).setup(quickyhash, &block)
    end

  public

    def registerBrush name, brush
      case brush
      when Brush then @brushes[name] = brush.qtc
      when Gradient then @brushes[name] = Qt::Brush.new(brush.qtc)
      else raise "Cannot register a #{brush.class}"
      end
    end

    def registerPen name, pen
      @pens[name] = pen.qtc
    end

    def registeredPen(name)
      @pens[name]  # THIS IS EVIL || :black
    end

    def registeredBrush(name)
      @brushes[name] # ... || :white
    end

#     def registerGroupMacro name, group
#       @groups[name] = group
#     end

    # Set the default fill for elements.
    def fill brush = nil
      return (@brush || defaultBrush) unless brush
      @brush = case brush
      when Symbol
#         tag "is #{brush} registered? -> #{@brushes[brush]}"
        @brushes[brush] || color2brush(brush)
      when Qt::Brush then brush         # trivial speed-up case
      else make_brush(brush)
      end
    end

    # Set the default stroke for elements
    def stroke pen = nil
      return (@pen || defaultPen) unless pen
      @pen = case pen
      when Symbol
        @pens[pen] || color2pen(pen)
      when Qt::Pen then pen
      else make_pen(pen)
      end
    end

    alias :brush :fill
    alias :pen :stroke

  #override
    def addGraphicsItem control, quickyhash = nil, &block
#       tag "addControl, control #{control} is added to SCENE"
#       qc = if control.respond_to?(:qtc) then control.qtc else control end             BOGO we call 'setup' two lines ahead anyway!
      @qtc.addItem control.qtc
      control.parent = self
      control.setup quickyhash, &block
      added control
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

    def_delegators :@qtc, :clear

        #override
    def addTo parent, hash, &block
      parent.addScene(self, hash, &block)
    end

  end # class Scene

  createInstantiator :scene, Qt::GraphicsScene, Scene

end # Reform