
#  Copyright (c) 2010 Eugene Brazwick

module Reform

  require 'reform/labeledwidget'
  require 'reform/abstractlistview'

=begin rdoc

ComboBox is a relative of ListView.
It works exactly the same. To incorparate this,we introduce AbstractListView with
the complete implementation.

The following datasources are supported:

  stringarrays.
  hash with stringvalues (and any index)
  hash with model-objects (and any index)
  array with model-objects

If the model uses  model-objects then these are sent and received by the connectors.
Otherwise, if it is a hash we use the keys,
otherwise, we use the values (strings) as a last resort.

See examples/models/demo03.rb

=========================================================


=end
  class ComboBox < AbstractListView
    include LabeledWidget::Implementation

    private

      def initialize parent, qtc
        super
        # @index and @data represent the local model as set with the 'model' (or specific model instantiator)
        # method.  Alternatively data becomes available through the application of @model_connector to
        # the connectedModel
  #       @model_connector = nil
        connect(@qtc, SIGNAL('activated(int)'), self) do |idx|
          rfRescue do
#             tag "Activated(#{idx})"
            if model && (cid = connector) && model.setter?(cid)
              activated(model, cid, idx)
            end
          end
        end
      end # initialize

#       def currentKey k
  #       tag "currentKey := #{k.class}#{k}, index=#{@index.inspect}, index[k]=#{@index[k]}"
  #       k = k.to_i if k.respond_to?(:to_i)  # this fixes Qt::Enum identity crises (I hope) AARGH
#         @qtc.currentIndex = @index[enum2i(k)] || -1
  #       tag "currentIndex is now #{@qtc.currentIndex}"
#       end

      define_simple_setter :currentIndex

      # can be overriden. Called when combobox index, value has been decided
      def setCurrentIndex index
        @qtc.currentIndex = index
      end

    public

      # use this instead of connecting 'activated'
      def whenActivated &block
        if block
          connect(@qtc, SIGNAL('activated(int)'), self) do |idx|
            tag "idx = #{idx}, data_to_transmit[idx] = #{data_at(idx).inspect}"
            rfCallBlockBack(data_at(idx), idx, &block)
          end
        else
          @qtc.activated(@qtc.currentIndex)
        end
      end #whenActivated

  end # class ComboBox

  createInstantiator File.basename(__FILE__, '.rb'), Qt::ComboBox, ComboBox
end