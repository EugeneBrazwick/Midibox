
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require 'reform/abstractlistview'

=begin rdoc

a ListView gives you the view on a single column (if applicable, and default the first)
of a model.
=end
  class ListView < AbstractListView

    private

#       def initialize parent, qtc
#         super
#         initAbstractListView
#       end

      # override
      def setLocalModel aModel
        m = @qtc.selectionModel
        m.dispose if m
        super
      end

      # default is false, set it to true only if items are indeed all of equal size
      define_simple_setter :uniformItemSizes,
                           :dragEnabled, :dropIndicatorShown,
                           :spacing

      # set the size of icons
      def iconSize x = nil, y = nil
        return @qtc.iconSize unless x
        viewMode :icons
        case x
        when Qt::Size then @qtc.setIconSize(x)
        when Array then @qtc.setIconSize(Qt::Size.new(*x))
        else @qtc.setIconSize(Qt::Size.new(x, y || x))
        end
      end

      # activate the grid (invisible)
      def gridSize x = nil, y = nil
        return @qtc.gridSize unless x
        case x
        when Qt::Size then @qtc.setGridSize(x)
        when Array then @qtc.setGridSize(Qt::Size.new(*x))
        else @qtc.setGridSize(Qt::Size.new(x, y || x))
        end
      end

      MovementMap = { static: Qt::ListView::Static, free: Qt::ListView::Free, snap: Qt::ListView::Snap }

      # set the movement type. can be :static, :free or :snap
      def movement mv = nil
        case mv
        when nil then return @qtc.movement
        when Symbol then @qtc.movement = MovementMap[mv] || Qt::ListView::Static
        else @qtc.movement = mv
        end
      end

      # set the viewmode, can be :list or :icons
      def viewMode vm = nil
        case vm
        when nil then return @qtc.viewMode
        when :text, :list then vm = Qt::ListView::ListMode
        when :icon, :icons then vm = Qt::ListView::IconMode
        end
        @qtc.viewMode = vm
      end

      # sets the current index. Argument can be an integer
      def currentIndex n
        n = @qtc.model.index[n] if Fixnum === n
        @qtc.currentIndex = n
      end

      alias :currentIndex= :currentIndex

    public

      # override        TOO SOON!!!
#       def setLocalModel aModel
#         (sm = @qtc.selectionModel) and sm.deleteLater
#         super
#         tag "addedModel #{aModel}, model.qtc = #{aModel.qtc}, @model = #@model, qtc= #@qtc, qtc.model = #{@qtc.model}"
#         tag "aModel.length = #{aModel.length}, aModel.empty?= #{aModel.empty?}"
#         unless aModel.empty?
#           @qtc.currentIndex = @qtc.model.index(0)             ???????????
#         end
#       end

      # passed to this callback are two Qt::ModelIndex instances. These give both row and value
      # using row, column and data methods. 'data' returns a Qt::Variant though.
      def whenCurrentChanged current = nil, previous = nil, &block
        if block
          @whenCurrentChanged = block
        else
#           tag "changed, assign '#{current.data.value}' to models property cid=#{connector}, effectiveModel=#{effectiveModel}"
          if model && (cid = connector)
            activated(model, cid, current.row, current.data)
          end
          rfCallBlockBack(current, previous, &@whenCurrentChanged) if instance_variable_defined?(:@whenCurrentChanged)
        end
      end

      def setCurrentIndex idx
#         tag "Calling #{qmodel}.index(#{idx}, #{@qtc.modelColumn})"
        idx = @qtc.model.index(idx, @qtc.modelColumn)
        @qtc.currentIndex = idx if idx.valid?
      end

  end # class ListView

  class QListView < Qt::ListView
    include QWidgetHackContext
#       def paintEvent event
#         tag "paintEvent"
# #         super
#       end

#       def visualRect(item)
#         r2 = super.tap{|r| tag "visualRect(#{item}) -> #{r.inspect}" }
#         super.tap{|r| tag "visualRect(#{item}) -> #{r.inspect}" }
#         r2.height = 16 if r2.height < 0               SEGV
#         Qt::Rect.new(0, 0, 100, 32)
#       end

      # signal
      def currentChanged current, previous
#         tag "currentChanged to #{current.row} from #{previous.row}"
        @_reform_hack.whenCurrentChanged(current, previous) #if instance_variable_defined?(:@_reform_hack)
      end
  end

  createInstantiator File.basename(__FILE__, '.rb'), QListView, ListView

end # module Reform