
# Copyright (c) 2010-2011 Eugene Brazwick

require 'reform/abstractitemview'

module Reform

=begin
  DESIGN ERROR.
  Only if the connector value changes will the view get new data (see Control::updateModel)
  This means that the values for some of the role-connectors may change but we will
  never know it...

  This is in particular true for the model_connector!

  This means that updateModel has to be changed considerably
=end
  # this module implements combobox and listbox functionality
  # by using a Qt::AbstractListModel interface
  # Internally we use a 'local' model to supply the list with values.
  # This can be added by instantiating a model within a list or combo.
  class AbstractListView < AbstractItemView
    extend Forwardable

      QAbstractListModel = QAbstractItemModel

      # this class forms the hinge between 'list' (or 'combo' etc) and any 'model' (like Structure) 
      class QModel < Qt::AbstractListModel
        include QAbstractListModel

        private
          def initialize reformmodel, reformview
#	    tag "new QModel"
            if Qt::Object === reformmodel
              super(reformmodel)
            else
#               tag "creating PARENTLESS model"
              super()
#               tag "parent = #{parent}" # Parent is somehow a Qt::ModelIndex.  ??????????????????? WEIRD
            end
            @localmodel = reformmodel # apparently.
            @view = reformview
            # connectors is a hash with these optional entries:
            # :model                    to be applied on the connecting model, the result is the listmodel
            # @connector itself:        let's say we have a list with colors, where each color is retrieved using :col
            #                           but the connecting model use :bordercolor.
            #                           In that case @connectors[:display] == :col while @connector == :bordercolor
            #                           Also accessible as view.connectors[:external]
            # :external                 Same as @connector
            # :display                  to be applied to a record in the list. defaults to 'to_str', then 'to_s' , must be a string
            #                           Formerly known as local_connector
            # :editor                   same, defaults to :display, -> string
            # :decoration               "", but default nil, must be color, icon or pixmap (why not a brush?)
            # :tooltip                  idem, must be a string
            # :statustip                ""
            # :whatsthis                ""
            # :sizehint                 "" -> Qt::Size or tuple [x,y]
            # :font                     "" must be a Qt::Font
            # :alignment (of text)      "" must be a Qt::AlignmentFlag
            # :background (brush)       "" must be a Qt::Brush
            # :foreground (say textcolor or fill)   idem
            # :checked                  "", must be Qt::CheckState
            # :accessibletext
            # :accessibledescription
#             @connectors = {}
            # this means that instead of a fixed property of that kind, we apply the connector
            # to the passed model instead (the row/record).
            # Syntax:  connectors local: .., display:
            # And connector x is the same as connectors display: x
#             tag "QModel.new(#{reformmodel})"
          end

    # #       alias :reform_model :parent

=begin
      the local model can be a
        - stringlist
        - modelvalue array
        - stringvalue hash

  the hash order is the ruby sequential order. So we use localmodel[localmodel.keys[i]] to get the value

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

      end # class QModel

  private # methods of AbstractListView

      def initialize parent, qtc   #  prev: initAbstractListView
        super
        column
      end

      def col0
        @col0 ||= col(0)
      end

      def_delegators :col0, :local_connector, :display_connector, :display,
                            :itemdecoration, :decoration, :decorator,
                            :itemtooltip, :itemstatustip, :whatsthis, :itemfont,
                            :itembackground, :itemcolor, :itemchecked,
                            :connector, :connectors

      def createQModel
#        tag "creating QModel, localmodel = #@localmodel"
        QModel.new(@localmodel, self)
      end

=begin
  My question is: what is data_idx? I think value given from QModel#data?
  In that case it is pretty useless. Maybe handy for debugging
=end
      def activated model, cid, idx, data_idx = nil
        #tag "YES, 'activated'!!!, idx = #{idx}, cid=#{cid}, model=#{model},
        data_to_transmit=#{@localmodel.model_index2value(idx, self).inspect}, debug_track = #@debug_track"
        model.model_apply_setter cid, @localmodel.model_index2value(idx, col0), self #, debug_track: true
      end

      #override. Select the correct index in the view based on the single value
      # that we connect to.
      def applyModel value
        #tag "#{self}::applyModel #{value.inspect}, #@model, cid=#{connector.inspect}"
        if modcon = @model_connector
          # change the contents first
          #tag "applying model_connector #{modcon}"
          setLocalModel @model.model_apply_getter(modcon)#.tap{|r| tag "setLocalModel(#{r.inspect})!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" }
        end
        # it's not entirely clear when the events are triggered
	raise "#{self} (name:#{name}) has no local model set" unless @localmodel
        # - currentIndexChanged(int)
        # - currentIndexChanged(string)
        # - editTextChanged(string). Must 'editable' be true for this??
        # It should be possible to make a combobox with immediate 'add' and 'delete'
        # capabilities that operate on the local model.
        # Note that the setter is supposed to accept the VALUE at the given index
        # and the getter receives the VALUE too.
        #tag "calling #{@localmodel}#model_value2index(#{value}, col0 = #{col0}"
        if i = @localmodel.model_value2index(value, col0)
          raise "#{@model}.model_value2index(#{value.inspect}) -> #{i}???, caller=#{caller.join("\n")}" unless Fixnum === i
          #tag "Calling setCurrentIndex(#{i})"
          setCurrentIndex i
        else
	  #tag "COULD NOT LOCATE #{value.inspect}"
          STDERR.print "Warning: could not locate value %s in %s\n" % [value.inspect, self.to_s] if $VERBOSE
          setCurrentIndex 0
        end
      end # def apply_model

      # override
      def check_propagation_change propagation, cid
        if propagation.debug_track?
          STDERR.print "#{self}::check_propagation_change, cid=#{cid} @connectors[:model]= " +
                       "#{@connectors && @connectors[:model]}, " + "propagation.keypaths=#{propagation.changed_keys.inspect}\n"
        end
        propagation.get_change(cid) ||
        (modcon = col0.connectors[:model]) && propagation.get_change(modcon)
      end

    public # methods of AbstractListView

  end # class AbstractListView
end
