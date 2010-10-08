
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require 'reform/widget'
  require 'reform/abstractlistview'

=begin rdoc

a ListView gives you the view on a single column (if applicable, and default the first)
of a model.
=end
  class ListView < Widget
    include ModelContext, AbstractListView

    private

      def initialize parent, qtc
        super
        initAbstractListView
      end

      # default is false, set it to true only if items are indeed all of equal size
      define_simple_setter :uniformItemSizes,
                           :dragEnabled, :dropIndicatorShown,
                           :spacing

      def iconSize x = nil, y = nil
        return @qtc.iconSize unless x
        case x
        when Qt::Size then @qtc.setIconSize(x)
        when Array then @qtc.setIconSize(Qt::Size.new(*x))
        else @qtc.setIconSize(Qt::Size.new(x, y || x))
        end
      end

      def gridSize x = nil, y = nil
        return @qtc.gridSize unless x
        case x
        when Qt::Size then @qtc.setGridSize(x)
        when Array then @qtc.setGridSize(Qt::Size.new(*x))
        else @qtc.setGridSize(Qt::Size.new(x, y || x))
        end
      end

      MovementMap = { static: Qt::ListView::Static, free: Qt::ListView::Free, snap: Qt::ListView::Snap }

      def movement mv = nil
        case mv
        when nil then return @qtc.movement
        when Symbol then @qtc.movement = MovementMap[mv] || Qt::ListView::Static
        else @qtc.movement = mv
        end
      end

      def viewMode vm = nil
        case vm
        when nil then return @qtc.viewMode
        when :list then vm = Qt::ListView::ListMode
        when :icon, :icons then vm = Qt::ListView::IconMode
        end
        @qtc.viewMode = vm
      end

      def currentIndex n
        n = @qtc.model.index[n] if Integer === n
        @qtc.currentIndex = n
      end

      alias :currentIndex= :currentIndex

    public

      def addModel aModel, hash, &block
        (sm = @qtc.selectionModel) and sm.deleteLater
        super
        tag "addModel #{aModel}, qtc = #{aModel.qtc}"
#         tag "aModel.length = #{aModel.length}, aModel.empty?= #{aModel.empty?}"
        unless aModel.empty?
          @qtc.currentIndex = @qtc.model.index(0)
        end
      end

      # passed to this callback are two Qt::ModelIndex instances. These give both row and value
      # using row, column and data methods. 'data' returns a Qt::Variant though.
      def whenCurrentChanged current = nil, previous = nil, &block
        if block
          @whenCurrentChanged = block
        else
#           tag "changed, assign '#{current.data.value}' to models property cid=#{connector}, effectiveModel=#{effectiveModel}"

          if (model = effectiveModel) && (cid = connector)
            activated(model, cid, current.row, current.data)
          end
          rfCallBlockBack(current, previous, &@whenCurrentChanged) if instance_variable_defined?(:@whenCurrentChanged)
        end
      end

      def setCurrentIndex idx
        qmodel = @qtc.model
#         tag "Calling #{qmodel}.index(#{idx}, #{@qtc.modelColumn})"
        idx = qmodel.index(idx, @qtc.modelColumn)
        @qtc.currentIndex = idx if idx.valid?
      end

  end # class ListView

  class QListView < Qt::ListView
      def currentChanged current, previous
#         tag "currentChanged to #{current.row} from #{previous.row}"
        @_reform_hack.whenCurrentChanged(current, previous) if instance_variable_defined?(:@_reform_hack)
      end
  end

  createInstantiator File.basename(__FILE__, '.rb'), QListView, ListView

end # module Reform