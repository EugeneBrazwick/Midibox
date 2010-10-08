
# Copyright (c) 2010 Eugene Brazwick

module Reform

  # this module implements combobox and listbox functionality
  # by using a Qt::AbstractListModel interface
  # Internally we use a 'local' model to supply the list with values.
  # This can be added by instantiating a model within a list or combo.
  module AbstractListView

      # this class forms the hinge between 'list' (or 'combo' etc) and any 'model' (like ruby_model/simpledata)
      class QModel < Qt::AbstractListModel
        private
          # the parent is a Reform Model.
          def initialize model, local_conn, deco_conn
            super(model)
            @local_conn = local_conn # not nil
            @deco_conn = deco_conn # can be nil
#             tag "QModel.new(#{model})"
          end

    # #       alias :reform_model :parent

=begin
      the local model can be a
        - stringlist
        - modelvalue array
        - stringvalue hash

  the hash order is the ruby sequential order. So we use local_model[local_model.keys[i]] to get the value

  However, the ListView wants only strings for data (and icons).

stringlist
------------------------
The data is a stringcompatible value.  When connected we locate the matching string in the list.
When altered, the string is send away as data

stringvalue hash
------------------
The key is the data(!) When connected we locate the key in the model and find the actual index. When altered
the key for that index is send away. For this populate @keys.

object array
-------------
The object is the data.  When connected we apply 'to_s' to the object to receive the contents,
When altered the object located at that position is sent.
So this is almost the same as stringlist, except we don't expose the object to Qt. The interfacing
is pure by index, but this works the same for any array.

object hash
-------------
Not supported yet

=end
        public

          def local_model
            parent
          end

          def rowCount parent
            local_model.length # .tap {|l| tag "rowCount->#{l}"}
          end

          def data index, role = Qt::DisplayRole
#             tag "data at #{index.row}, role = #{role} DisplayRole=#{Qt::DisplayRole}, EditRole=#{Qt::EditRole}"
            case role
            when Qt::DisplayRole, Qt::EditRole
#               tag "DATA-> #{local_model[index.row]}"
              Qt::Variant.from_value(local_model[index.row].apply_getter(@local_conn))
            when Qt::DecoratorRole
              @deco_conn ? Qt::Variant.from_value(local_model[index.row].apply_getter(@deco_conn)) : Qt::Variant.new
            else
              # an example would be Qt::SizeHintRole
              Qt::Variant.new # aka invalid or 'I don't care'
            end
          end

      end # class QModel

    private

      def initAbstractListView
        @hash_based = false # hash with stringvalues only.
      end

      # the 'local' connector, that connects to the local 'model'
      # and if set is applied as 'getter' to fetch the strings belonging to each object
      # within the model
      def local_connector sym
        @local_connector = sym
      end

=begin
  My question is: what is data_idx? I think value given from QModel#data?
  In that case it is pretty useless. Maybe handy for debugging
=end
      def activated model, cid, idx, data_idx = nil
#         tag "YES, 'activated'!!!, idx = #{idx}, cid=#{cid}, model=#{model}, data_to_transmit=#{data_at(idx).inspect}"
        model.apply_setter cid, data_at(idx), self
      end

      # where idx is numeric
      def data_at idx
        @qtc.model.local_model.data_at(idx)
      end

      # def override the class. I need not even be a QModel...
#       def qModel klass
#         @qmodel = QModel
#       end

      def setLocalModel aModel
#         clearList
        # key2index contains the map from key to index, in case we have keys.
#         @key2index = nil
        # keys is the map from index to key. If not nil we use it. And we are in the case where
        # local model is a hash with stringvalues
#         @index2key = nil
        local_connector = instance_variable_defined?(:@local_connector) && @local_connector || :to_s
        deco_connector = instance_variable_defined?(:@deco_connector) && @decol_connector
        @qtc.model = aModel.qtc || QModel.new(aModel, local_connector, deco_connector)
      end

      #override. Select the correct index in the view based on the single value
      # that we connect to.
      def applyModel value, aModel
#         tag "apply_model #{value.inspect}, #{aModel}, cid='#{connector}'"
        if instance_variable_defined?(:@model_connector)
          # change the contents first
#           tag "applying model_connector #@model_connector"
          setLocalModel aModel.apply_getter(@model_connector)
        end
#         tag "getter '#{cid}' located"
        # it's not entirely clear when the events are triggered
        # - currentIndexChanged(int)
        # - currentIndexChanged(string)
        # - editTextChanged(string). Must 'editable' be true for this??
        # It should be possible to make a combobox with immediate 'add' and 'delete'
        # capabilities that operate on the local model.
        # Note that the setter is supposed to accept the VALUE at the given index
        # and the getter receives the VALUE too.
        i = @qtc.model.local_model.value2index(value)
        raise "#{aModel}.value2index(#{value.inspect}) -> #{i}???" unless Fixnum === i
#         tag "Calling setCurrentIndex(#{i})"
        setCurrentIndex i
      end # def apply_model

    public

      def addModel aModel, quickyhash, &block
#         tag "addModel(#{aModel})"
        super
        setLocalModel(aModel) if aModel
      end
  end # module AbstractListView
end