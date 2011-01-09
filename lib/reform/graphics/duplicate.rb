
# Copyright (c) 2011 Eugene Brazwick

=begin

based a bit on Replicator a Duplicator truly duplicates the things put in it.
Matrix is applied to each copy, otherwise they would all overlap completely.

How to instantiate components?
We must use a macro like system to replay construction

  duplicator {
    count 2
    square geometry: [10, 10, 50]
    translation 10, 10
  }

that 'square' should not be made here.
Setup must do this calling recreate_all.

Incremental count changes?
Would be much nicer.
It is possible that a duplicate has 3 different items. With a count of 10
that would be 30 items.
If count becomes 9 we must kill 27..29. If count becomes 11 we must
create 30..32.
So it is very important to know how many items are stored in the duplicate.
It also seems important to hold the qtitem pointers that basicly are our
children.

If one item changes they must ALL change. Even though they are individual copies??

  duplicator {
    count 5
    square geometry: [10, 10, 50], brush: { connector: :color }
    translation 10, 10
  }

If the brush of square changes like this, it must be for all copies as well, or
only a single one (and which one) will change.

Do we know if a component changes its appearance?

Is it possible to really use only 1 qtobject.
But in that we would have QReplicate... literally.
And that is bit unreliable at the moment, because I have no clue whether my overrides for
boundingRect (shape is even missing) are correct.

At least we need 'emtpy' clones which set pen,brush,matrix and are a proxy to a shared item.
As far as I know a graphic item can only have a single parent, and changing the parent
moves the item in the tree, so it is impossible to share them in that way.

But above example is contrived.

  duplicator {
    brush: { connector: :color }
    count 5
    square geometry: [10, 10, 50]
    translation 10, 10
  }

this is the correct version.

However, that's because brush happens to be movable in a convenient way.

It is also possible to put a connector on 'geometry', and the problem resurfaces.

The whole problem with the duplicate is that the concept of 'qtc' no longer applies.
There are now 'count' qtc's.

====================================================================
And something else, the passing of matrices can actually NEVER WORK.

Design error encountered
====================================================================

Take the 5 squares for example, we want to add a matrix to each of them, but
that can not be the same matrix.

Hm, it does not seem to be too problematic. The matrix as set to Duplicate
functions as base multiplier. When creating the qtc's we reapply it on
a temp accumulator, that is used to apply to the qtc.

Let's put it this way:
Duplicate and Replicate should behave exactly the same!
So let's focus first on getting Replicate to work 100%.
The only use of Duplicate is that painting is a lot faster
so it works better when there are many items.
On the other hand, if the structure changes frequently of
transformations, colors, any other attributes then you gain by using
the replicator, since the costs of these are extremely small.

A recursive duplicator (or replicator) can both kill your machine easily!!!

=======================

better solution: the duplicate keeps tracks of its contents separately
except for pen,brush,matrix and count.
Then we apply the resulting set count times. This will create a Reform
control + a Qt GraphicItem for each count.

=end

require_relative 'empty'

module Reform

  class Transform < Qt::Transform
      def to_s
        super + '((%3.4f,%3.4f,%3.4f),(%3.4f,%3.4f,%3.4f),(%3.4f,%3.4f,%3.4f))' % [m11,m12,m13,m21,m22,m23,m31,m32,m33]
      end
  end

  # real replicator repeats its contents while building using transformations
  class Duplicate < Empty # currently Empty == GraphicItem
    include SceneFrameMacroContext
    private
      def initialize parent, qparent
        super
        # ?
        @did_macros = false
      end

      # IMPORTANT fillhue_rotation DOES NOT WORK TODO
      # Neither does changing these parameters!!! TODO
      # Even if they are declared as controllers!!!  TODO
      # colorscale might also be interesting.
      # or, if we think H,S,V then both S and V can be scaled by a simple triplet
      #   [H-rot, S-scale, V-scale]
      define_setter Float, :degrees, :rotation
        # , :fillhue_rotation
      define_setter Integer, :count

      # TODO: make this DynamicAttributes too!
      def translation x, y = nil
        x, y = x if Array === x
        @qtc.translation = x, y || x
      end

      # TODO: make this DynamicAttributes too!
      def scale x, y = nil
        x, y = x if Array === x
        @qtc.scale = x, y || x
      end

      # override. they must be executed in parent!!
      # OR ELSE...
      # or else they are executed here, causing the instantiator to be called which
      # adds a macro to the list of macros we are currently executing. OOPS.
      # and hence addGraphicsItem below is NEVER EVER called, since all items are added
      # to the parent.
      # So a hack is required. We must execute them here and hence disable the macro building
      # mechanism.
      def executeMacros(receiver = nil)
#         tag "#{self}#executeMacros, EXECUTE #{instance_variable_defined?(:@macros) && @macros.length} macros"
        @disable_macros_in_context = true
        return unless instance_variable_defined?(:@macros)
        matrix = @qtc.matrix
#         tag "current matrix = #{matrix.inspect}"
        @mat = Transform.new # ouch
        @qtc.count.times do
          @macros.each do |macro|
#             tag "#{self}::Executing MACRO #{macro.name}#{macro.quicky.inspect}"
            macro.exec(self)
          end
#           tag "newmat := #{@mat.inspect} * #{matrix.inspect}"
          @mat *= matrix
        end
        remove_instance_variable(:@mat)
        remove_instance_variable(:@disable_macros_in_context)
        @did_macros = true
#         tag "HERE"
      end

    public # Duplicate methods

      def did_macros?; @did_macros; end

      # this should only be called by executeMacros and then @mat is actually set
      def addGraphicsItem control, quickyhash = nil, &block
#         tag "addGraphicsItem"
        qc = if control.respond_to?(:qtc) then control.qtc else control end
        super
# #         tag "addGraphicsItem c=#{control}, qc=#{qc}, adding mat"
#         tag "mat = #{@mat.inspect}"
        qc.setTransform @mat # if instance_variable_defined?(:@mat)
        control
      end

  end # class Duplicate

  class QDuplicate < QEmpty
    private
      def initialize qparent
        super
        @count = 0
        @scale, @rotation, @translation, @fillhue_rotation = nil, nil, nil, nil
        @matrix = nil
      end

      def reapply_matrix
        @matrix = nil
        matrix
        mat = Transform.new
        childItems.each do |child|
          child.setTransform mat
          mat *= @matrix
        end
      end

    public # QDuplicate methods
      def degrees= v
#         tag "degrees := #{v}"
        @degrees = v
        reapply_matrix
      end

      def scale= v
#         tag "scale := #{v}"
        @scale = v
        reapply_matrix
      end

      def rotation= v
#         tag "rotation := #{v}"
        @rotation = v
        reapply_matrix
      end

      def fillhue_rotation= v
        @fillhue_rotation = v
        reapply_fillhue
      end

      def count= v
#         tag "count := #{v}"
        @count = v
        recreate_all if @_reform_hack.did_macros?
      end

      def translation= v
#         tag "translation := #{v}"
        @translation = v
        reapply_matrix
      end

      # does not return nil
      def matrix
        unless @matrix
#           tag "calc mat, tran=#{@translation}, rot=#@rotation, scale=#@scale, count=#@count"
          @matrix = Transform.new
          @matrix.rotate(@rotation) if @rotation
          @matrix.scale(*@scale) if @scale
          @matrix.translate(*@translation) if @translation
        end
        @matrix
      end

      attr :count
  end # class QDuplicate

  createInstantiator File.basename(__FILE__, '.rb'), QDuplicate, Duplicate

end # module Reform
