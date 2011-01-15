
module Reform

# you can build a brush, pen and graphicitem pool.
# For colors use brushes as well.
  class DefinitionsBlock < Control
    include Graphical

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
            STDERR.print "FIXME, ignoring quicky + block\n" # should be working on the group.
  #           receiver.setup ???
            executeMacros(receiver)
          end

      end # class GroupMacro

    private # DefinitionsBlock methods

      def shapegroup quickyhash = nil, &block
        GroupMacro.new(quickyhash, &block)
      end

        # I see a pattern here (FIXME)
      def brush *args, &block
        make_qtbrush(*args, &block)
      end

      alias :fill :brush

      def pen *args, &block
#             tag "Scene:: pen"
        make_qtpen(*args, &block)
      end

      alias :stroke :pen

      def font *args, &block
        make_qtfont(*args, &block)
      end

    public  #DefinitionsBlock methods

      def method_missing sym, *args, &block
#         tag "#{self}::method_missing(:#{sym}), argslen=#{args.length}, block=#{block}"
        if args.length == 1 && !block
#           tag "single arg: #{self}.#{sym}(#{args[0]})"
          case what = args[0]
          when Qt::Brush, Brush, Gradient then parent.registerBrush(sym, what)
          when Qt::Pen, Pen then parent.registerPen(sym, what)
          when Qt::Font, Font then parent.registerFont(sym, what)
            # parent is always the scene
          when GroupMacro then registerGroupMacro(parent, sym, what)
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

end # Reform
