
module Reform

# you can build a brush, pen and graphicitem pool.
# For colors use brushes as well.
  class DefinitionsBlock < Control
    include Graphical

    private # DefinitionsBlock methods

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

      def parameters quicky = nil, &block
        Macro.new nil, nil, quicky, block
      end

=begin
    This is the same as 'parameters' except for this:
      1) the entire set is stored inside an implicit 'empty'
      2) when calling another hash + block can be passed
      3) the name becomes avaible as a 'graphic'. Note that it always is an 'empty'.

Example:

    define {
        myshape shapegroup {
          circle ...
          circle ...
          square ...
        }
      }

   canvas {
      myshape pos: [10, 10]
      myshape pos: [5, 5], rotation: 45
    }

=end
      def shapegroup quicky = nil, &block
        raise 'DAMN' if quicky && !(Hash === quicky)
        GroupMacro.new nil, nil, quicky, block
      end

    public  #DefinitionsBlock methods

      def method_missing sym, *args, &block
#         tag "#{self}::method_missing(:#{sym}), argslen=#{args.length}, block=#{block}"
        if args.length == 1 && !block
#           tag "single arg: #{self}.#{sym}(#{args[0]})"
          case what = args[0]
          when Qt::Brush, Brush, Gradient then containing_form.registerBrush(sym, what)
          when Qt::Pen, Pen then containing_form.registerPen(sym, what)
          when Qt::Font, Font then containing_form.registerFont(sym, what)
            # parent is always the scene
          when GroupMacro
            containing_form.parametermacros[sym] = what
            Graphical::registerGroupMacro(sym, what)
          when Macro then containing_form.parametermacros[sym] = what
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
