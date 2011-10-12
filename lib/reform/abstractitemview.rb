
#  Copyright (c) 2010 Eugene Brazwick

module Reform

  require 'reform/widget'

  class AbstractItemView < Widget
    include ModelContext

=begin

  It should be possible to say:

    pieview {
      decorator :color   # blob. You can also pass an image as icon
      key_connector :section
      label_connector :section
      value_connector :count
    }

=end
      # interfaces with Model.
      # It would be nice if AbstractListView could also use this,
      # but QModel inherits Qt::AbstractListModel instead.
      # But we will see.
      # actually, it should just work as a list is a 1-column table and nothing more than that
      # However Qt::AbstractListView has some internal tweaking that cannot be done
      # in ruby. So better be careful.
      # Qt::AbstractItemModel uses data-squares with sublevels. That's why it can be
      # used for trees and tables (and hence simplistic lists)
      module QAbstractItemModel

#           QInvalidIndex = Qt::ModelIndex.new # this may cause SEGV if deleted

        public
          attr :localmodel

          def rowCount parent = Qt::ModelIndex.new
#             tag "#{self}.rowCount, lmodel = #{localmodel}"
            localmodel.length #.tap {|l| tag "#{self}::rowCount->#{l}"} # works fine
          end

          def columnCount parent = Qt::ModelIndex.new
            @view.columnCount #.tap{|r|tag "columnCount->#{r}"}
          end

          # is it possible to use a bogo variant constant??
          # it seems, yes, you can
          ##            Bogo = Qt::Variant.new   CAUSES MAYHEM (sometimes??)

          # this is rather tricky. The enums cannot be used as a hashkey.  But I noticed that already
          # when attempting to use them as key in combobox setups...
          Role2ConnMap = { Qt::DisplayRole.to_i=>:display,
                           Qt::EditRole.to_i=>:editor,
                           Qt::DecorationRole.to_i=>:decoration,
                           Qt::ToolTipRole.to_i=>:tooltip,
                           Qt::StatusTipRole.to_i=>:statustip,
                           Qt::WhatsThisRole.to_i=>:whatsthis,
                           Qt::SizeHintRole.to_i=>:sizehint,
                           Qt::FontRole.to_i=>:font,
                           Qt::TextAlignmentRole.to_i=>:alignment,
                           Qt::BackgroundRole.to_i=>:background,
                           Qt::ForegroundRole.to_i=>:foreground,
                           Qt::CheckStateRole.to_i=>:checked,
                           Qt::AccessibleTextRole.to_i=>:accessibletext,
                           Qt::AccessibleDescriptionRole.to_i=>:accessibledescription
                         }

#           raise "WTF, Qt::SizeHintRole = #{Qt::SizeHintRole} Role2ConnMap = #{Role2ConnMap.inspect}, Role2ConnMap[1] = #{Role2ConnMap[1]}, Role2ConnMap[13]=#{Role2ConnMap[13]}" unless Role2ConnMap[13] == :sizehint

          # If the list has 1000 rows, expect 8000 calls to this method. So it should be as fast as possible.
          def data index, role = Qt::DisplayRole
            #tag "#{self}#data at #{index.row}, role = #{role} DisplayRole=#{Qt::DisplayRole}, EditRole=#{Qt::EditRole}, SizeHintRole=#{Qt::SizeHintRole}, localmodel=#{localmodel}"
            record = localmodel.model_row(index.row)
            is_model = record.respond_to?(:model?) && record.model?
#            tag "localmodel= #{localmodel.inspect}, row = #{index.row}, record = #{record.inspect}"
            return Qt::Variant.new if record.nil?
            # it is far too dangerous defaulting this
#             tag "Qt::SizeHintRole = #{Qt::SizeHintRole.inspect}, to_i -> #{Qt::SizeHintRole.to_i}"
            connectorname = Role2ConnMap[role.to_i] or return Qt::Variant.new # raise ReformError, "Role #{role} not located in Role2ConnMap"           14,15,16,17.... ?
            connector = @view.col(index.column).connectors[connectorname]
#             tag "connectorname = #{connectorname}, connector = #{connector.inspect}"
            # we cannot use defaults for the others unless we would know that application of the getter would
            # return nil.  Otherwise everything would receive a tooltip etc..
            case connectorname
            when :display then connector ||= :to_s
            end
            value = case connector
            when Symbol
              if is_model
                record.model_apply_getter(connector)
              else
                connector == :self ? record : record.send(connector)
              end
            when Proc then is_model ? record.model_apply_getter(connector) : connector[record]
            else connector
            end
#             tag "raw valued returned for role :#{connectorname} for row #{index.row} is #{value.inspect}"
            case connectorname
            when :decoration
#               tag "deco fixup"
              case value
              when String
                if value[0, 7] == 'file://'
                  sz = @view.iconSize
                  img = Qt::Image.new(sz, Qt::Image::Format_ARGB32_Premultiplied)     # useless setting size
#                   tag "requested size = #{sz.inspect}"
                  # it loads 'svg' OK. But can you preset the size?
                  # otherwise it must be scaled.
                  img.load(value[7..-1])
                  raise Error, tr("Could not load image from file '#{value[7..-1]}'") if img.null?
#                   tag "actual size = #{img.size.inspect}"
                  value = if img.size == sz then img else img.scaled(sz, Qt::KeepAspectRatioByExpanding,
                                                                     Qt::SmoothTransformation) end
#                   raise Error, tr("Could not scale img") if value.null?
                else
                  value = Graphical::color(value)
                end
              when Symbol, Array
                value = Graphical::color(value)
              end
            when :sizehint
              case value
              when Numeric then value = Qt::Size.new(value, value)
              when Array then value = Qt::Size.new(*value)
              end
#               tag "sizehint FIXUP, value = #{value.inspect}"
            when :font
              raise "NIY" if String === value
            when :alignment
              raise "NIY" if Symbol === value
            when :checked
              case value
              when Symbol, FalseClass, TrueClass then raise "NIY"
              end
            when :background, :foreground
              case value
              when NilClass, Qt::Brush
              else
                value = Graphical::make_brush(value)
              end
            end
#             return value  # SEGV
            if value
#               tag "RETURNING #{index.row},#{index.column} -> #{value.inspect} to variant (for role #{role}, #{connectorname})"
              Qt::Variant::from_value(value)
            else
#               tag "RETURNING EMPTY DATA for role #{role}!!! #{index.row},#{index.column}"
              Qt::Variant::new
            end
          end

          # This conflicts with Qt::Object::parent!!!
          def parent index = nil
            index ? Qt::ModelIndex.new : super
          end

    # I think there is a default.
          def index row, column, parent = Qt::ModelIndex.new # rootIndex # QInvalidIndex
            createIndex(row, column)
          end

          # 'override'
          def supportedDropActions
#             tag "#{self}::supportedDropActions -> copy"
            Qt::CopyAction | Qt::MoveAction
          end

          # 'override'
          def flags index
            defaultFlags = super
            if index.valid? then Qt::ItemIsDragEnabled | Qt::ItemIsDropEnabled | defaultFlags
            else Qt::ItemIsDropEnabled | defaultFlags
            end
          end

          def mimeTypes
            #tag "mimeTypes"
            [localmodel.mimeType]
          end

          def mimeData indexes
#             tag "mimeData"
            return nil if indexes.empty?
            localmodel.mimeData(indexes.map { |i| localmodel.model_row(i.row) })
          end
      end # module QAbstractItemModel

      class QItemModel < Qt::AbstractItemModel
        include QAbstractItemModel
        private
          def initialize reformmodel, reformview
            super(reformmodel)
 #           tag "QItemModel.new(#{reformmodel}, #{reformview}"
            @localmodel = reformmodel # apparently.
            @view = reformview
          end
      end

      # the view is our parent
      class ColumnRef < Control
        private
          def initialize view
            super
    #         tag "new ColumnRef(#{header})"
            @view, @n = view, view.columnCount
            @connectors = {}
            @connector = @key_connector = @model_connector = nil    #  external connector
#             @label = ''
            @type = String
          end

          # sets the 'creator' like :combobox or :edit. Unset means :edit
          # unless there is a @model_connector, then we use :combobox as default
#           def editor quickyhash = nil, &block
#             @persistent_editor
#             @editor = Macro.new(nil, nil, quickyhash, block)
    #         @qtc.itemDelegate = @editor
#           end

          def self.declare_connector symbol, name = ('item' + symbol.to_s).to_sym
            define_method name do |value = nil, &block|
              @connectors[symbol] = value || block
              want_data!
            end
          end

          # :call-seq: local_connector symbol
          # the 'local' connector, that connects to the local 'model'
          # and if set is applied as 'getter' to fetch the strings belonging to each object
          # within the model
	  # if unset the view will attempt to make something out of the data itself
          declare_connector :display, :local_connector

	  # since local_connector refers to what is displayed, these aliases
	  # make that more clear
          alias :display_connector :local_connector
          alias :display :local_connector

              # sets decoration role connector
          declare_connector :decoration

          alias :decoration :itemdecoration
          alias :decorator :itemdecoration

          declare_connector :tooltip
          declare_connector :statustip
          declare_connector :whatsthis, :whatsthis
          declare_connector :font
          declare_connector :background
          declare_connector :foreground, :itemcolor
          declare_connector :checked

          # does not depend on the column!!
#           declare_connector :model, :model_connector

          # key_connector should not be here. The entire row can only have one key.
          # So it does not depend on the column.
#           declare_connector :key, :key_connector
#           alias :itemkey :key_connector

        public  # ColumnRef methods

          def type value = nil
            return @type if value.nil?
            @type = value
          end

          def var2data variant
#            tag "var2data, type = #{@type.inspect}"
            # IMPORTANT: String === String results in false!!!
            case @type.to_s
            when 'String' then variant.to_string
            when 'TrueClass', 'FalseClass' then variant.toBool
            when 'Integer' then variant.toInt
            when 'Float' then variant.toFloat
            else raise ReformError, "Missing method to convert Qt::Variant to a '#@type'. Please complain."
            end
          end

	  # this is how the external key is referred
          def connector value = nil, &block
            return super unless value || block
            super
    #         tag "connector(#{value.inspect}), #{self}.connector is now #{@connector.inspect}"
            @connectors[:external] = @connector if value || block
          end

          def key_connector
#             tag "#{self}::key_connector, forward to #@view"
            @view.key_connector
          end

          def model_connector
#             tag "#{self}::model_connector, forward to #@view"
            @view.model_connector
          end

          def connectors hash = nil
            return @connectors unless hash
            @connectors = hash
            connector(hash[:external]) if hash[:external]   # otherwise unaffected
          end

      end # class ColumnRef

    private # AbstractItemView methods

      SelectionModeMap = { :none => Qt::AbstractItemView::NoSelection,
                           :extended => Qt::AbstractItemView::ExtendedSelection,
                           :single => Qt::AbstractItemView::SingleSelection,
                           :multi => Qt::AbstractItemView::MultiSelection,
                           :contiguous => Qt::AbstractItemView::ContiguousSelection
                         }

      SelectionBehaviorMap = { :items => Qt::AbstractItemView::SelectItems,
                               :rows => Qt::AbstractItemView::SelectRows,
                               :columns => Qt::AbstractItemView::SelectColumns
                               }

      def selectionMode value = nil
        return @qtc.selectionMode unless value
        value = SelectionModeMap[value] || Qt::AbstractItemView::NoSelection if Symbol === value
        @qtc.selectionMode = value
      end

      def selectionBehavior value = nil
        return @qtc.selectionBehavior unless value
        value = SelectionBehaviorMap[value] || Qt::AbstractItemView::SelectItems if Symbol === value
        @qtc.selectionBehavior = value
      end

      def noSelection
        @qtc.selectionMode = Qt::AbstractItemView::NoSelection
      end

      def createColumnRef
#        tag "createColumnRef"
        ColumnRef.new(self)
      end

      def whenCurrentItemChanged &block
        raise 'DEPRECATED'
      end

      def whenItemChanged &block
        raise 'DEPRECATED'
      end

      def setLocalModel aModel
        raise 'WTF' unless aModel.model?
#         tag "#{self}::setLocalModel #{aModel}!!!!!!!!!!!!" #, caller = #{caller.join("\n")}"
        @localmodel = aModel
#          note: Qt::ComboBox has no 'selectionModel'. Only ListView and TableView.
        qm = @qtc.model = @localmodel.qtc || createQModel
#         tag "qm.parent = #{qm.parent}, localmodel = #@localmodel, self = #{self}, qtc=#@qtc"
        qm.parent = @qtc # fix 0028???  YES. For unknown reasons qm is somewhere freed...
        # since it is 'local' it is probably not wrong to set the parent.
#         tag "#@qtc.model is now #{@qtc.model}"
        @qtc.respond_to?(:dataChanged) && @qtc.dataChanged(Qt::ModelIndex.new, Qt::ModelIndex.new)      #this is stupid but
            # required for ORIGINAL pieview component...
        # qm.index(0,0), qm.index(qm.rowCount - 1, qm.columnCount - 1))
#         @qtc.show
      end

      def createQModel
#        tag "createQModel"
        QItemModel.new(@localmodel, self)
      end

      def column quickyhash = nil, &initblock
#        tag "column"
        ref = createColumnRef
        if quickyhash
          ref.setupQuickyhash(quickyhash)
        elsif initblock
          ref.instance_eval(&initblock)
        end
      end

    public # methods of AbstractItemView

      def columnCount
        @columnCount ||= find(ColumnRef).count
      end

#       alias :columncount :columnCount

      def col n
        find(ColumnRef).each_with_index { |el, i| return (@colcache||={})[n] ||= el if i == n }
        nil
      end

      def postSetup
        setLocalModel(@localmodel) if instance_variable_defined?(:@localmodel) && @localmodel
        super
      end

      # override, assign to @localmodel, not to @model
      def addModel control, hash = nil, &block
        control.setup hash, &block
        @localmodel = control
        #control.parent = self    no such method 'parent=' .. required ?
        added control
      end

      # the default is :id. This tells the view how to retrieve the 'key'
      # from a row.
      def key_connector value = nil
        return @key_connector unless value
        @key_connector = value
      end

      # a model_connector gives us the local model, as part of the global model.
      # For example calendermodel has 'weekdays' which can be used to fill a
      #combobox. So a model_connector is an alternative for providing a local model
      # otherwise. It does apply to $qApp.model or form.model
      def model_connector value = nil
        return @model_connector unless value
        @model_connector = value
      end

      alias :modelconnector :model_connector
      alias :keyconnector :key_connector

      def updateModel aModel, propagation
        if instance_variable_defined?(:@localmodel) && aModel == @localmodel
          setLocalModel(aModel)  # whatever changed. This may need to be more precise
        else
          super
        end
      end

  end # class AbstractItemView

end # module Reform
