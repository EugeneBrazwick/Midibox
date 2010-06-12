
#  Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../labeledwidget'

  class ComboBox < LabeledWidget
    include ModelContext
    private

    def initialize parent, qtc
      super
      # @index and @data represent the local model as set with the 'model' (or specific model instantiator)
      # method.  Alternatively data becomes available through the application of @model_connector to
      # the connectedModel
      @index = {}
      @data = []
#       @model_connector = nil
      connect(@qtc, SIGNAL('activated(int)'), self) do |idx|
        rfRescueContext do
          if (model = effectiveModel) && (cid = connector) && model.setter?(cid)
            activated(model, cid, idx)
          end
        end
      end
    end # initialize

    def activated model, cid, idx
#       tag "YES, 'activated'!!!, idx = #{idx}, cid=#{cid}, model=#{model}"
      model.apply_setter(cid, @data[idx])
    end

    # connector is the 'local' connector, that connects to the local 'model'
    # and if set is applied as 'getter' to fetch the strings belonging to each object
    # within the model
    def local_connector sym
      @local_connector = sym
    end

    def currentKey k
#       tag "currentKey := #{k.class}#{k}, index=#{@index.inspect}, index[k]=#{@index[k]}"
#       k = k.to_i if k.respond_to?(:to_i)  # this fixes Qt::Enum identity crises (I hope) AARGH
      @qtc.currentIndex = @index[enum2i(k)] || -1
#       tag "currentIndex is now #{@qtc.currentIndex}"
    end

    def enum2i k
      k.is_a?(Qt::Enum) ? k.to_i : k
    end

    # data can be array, hash, or any ruby object that includes Model or ActiveSOMETHING(niy)
    # and also Enumerable.
    # If data is a single symbol it is supposed to be the connector of the model itself.
    # if the combo was previously empty then the current index will be set to 0
    def model *data
#       tag "model(#{data}), FILLING MODE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
#       tag "caller=#{caller.join("\n")}" if data.empty?
      data = data[0] if data.length == 1 && (data[0].respond_to?(:each) || data[0].is_a?(Symbol))
      if data.is_a?(Symbol)
# 	tag "setting model_connector to #{data}"
        return @model_connector = data
      end
      # storing data in the combobox using Qt::Variant is very tricky.
      # since storing objid may dispose of the ruby object, as it is no longer
      # referenced. So we build a hash here, using key if possible, and the value
      # will be the index in the combobox. So findData can be implemented easily enough
      # luckely a single string is not an enumerable, and has no 'each' either.
      @index = {}
      # however, the key is not good enough. Adding the actual contents here:
      @data = []
#       tag "Cleaned data for combo '#{name}'"
      currentText = @qtc.currentIndex >= 0 && @qtc.currentText
#       tag "currentText mem = '#{currentText}'"
      @qtc.clear
      no_signals do
        # However, this duplicates the data passed to the combo, which seems a waste.
        # What about @data = data ??
        # assigning data like this should provide that @objhash[combo.itemdata] is the value
        # However, Qt::Enum may be problematic
  #       @objhash = data
        # comboboxes may have virtual contents. In that case use virtualcombo.
        # we use abuse datasource and copy it completely into Qt format.
        contor = instance_variable_defined?(:@local_connector) && @local_connector || :to_s
        if data.respond_to? :each_pair
  #         tag "data responds to 'each_pair'"
          i = 0
          data.each_pair do |k, obj|
            key = enum2i(k.respond_to?(:key) ? k.key : k)
#             key = key.to_i if key.respond_to?(:to_i)  # this fixes Qt::Enum identity crises (I hope) AARGH
#             key = enum2key.to_i if key.is_a?(Qt::Enum)
            @index[key] = i
#             tag "addItem[#{i}]:#{obj}, #{key.inspect}, keyclass=#{key.class})"
  #           key = k.is_a?(Qt::Enum) ? k.to_i : k
            if obj.respond_to?(:to_str)
              @data << k
  #             tag "addItem(#{obj.to_str})"
              @qtc.addItem(obj.to_str)
            else
              @data << obj
              @qtc.addItem(obj.send(contor))
            end
            i += 1
          end
        else
  #         tag "use data.each_with_index"
          data.each_with_index do |obj, j|
            key = enum2i(obj.respond_to?(:key) ? obj.key : obj)
#             key = key.to_i if key.respond_to?(:to_i)  # this fixes Qt::Enum identity crises (I hope)
              # RIDICULOUS, since strings also have to_i and it is always 0...
#             key = key.to_i if key.is_a?(Qt::Enum)
#             tag "@index[#{key.class}#{key}] := #{j}, obj=#{obj.class} #{obj}. has_key=#{obj.respond_to?(:key)}"
            @index[key] = j
            @data << obj
            @qtc.addItem(obj.respond_to?(:to_str) ? obj.to_str : obj.send(contor))
          end
        end
	nci = currentText ? @qtc.findText(currentText) : 0
# 	tag "restoring currentText '#{currentText}' => newindex := #{nci}"
        @qtc.currentIndex = nci
#         @qtc.currentIndex = index < 0 ? 0 : index
  #       tag "created index #{@index.inspect}, and data #{@data.inspect}"
      end # no signals
    end

    define_simple_setter :currentIndex

    # can be overriden. Called when combobox index, value has been decided
    def setCurrentIndex(index, value)
      @qtc.currentIndex = index
    end

    public

    # use this instead of connecting 'activated'
    def whenActivated &block
      if block
        connect(@qtc, SIGNAL('activated(int)'), self) do |idx|
          rfCallBlockBack(@data[idx], idx, &block)
        end
      else
        @qtc.activated(@qtc.currentIndex)
      end
    end #whenActivated

    #override. Select the correct index in the combobox based on the single value
    # that we connect to.
    def connectModel aModel, options = nil
#       tag "connectModel #{aModel}, cid='#{connector}',options=#{options.inspect}"
      if instance_variable_defined?(:@model_connector)
	# change the contents first
#  	tag "applying model_connector #@model_connector"
	contents = aModel.apply_getter @model_connector
# 	tag "contents = #{contents}"
	unless instance_variable_defined?(:@contents_cacheid) && @contents_cacheid.equal?(contents.__id__)
	  @contents_cacheid = contents.__id__
#           tag "FILLING THE COMBOBOX #{name}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	  model contents
#           tag "data is now #{@data.inspect}"
#           raise if @data.empty?
	end
      end
      cid = connector or return
#       tag "check for getter?(#{cid}) in #{model.class}"
      if aModel && aModel.getter?(cid)
#         tag "getter '#{cid}' located"
        # it's not entirely clear when the events are triggered
        # - currentIndexChanged(int)
        # - currentIndexChanged(string)
        # - editTextChanged(string). Must 'editable' be true for this??
        # It should be possible to make a combobox with immediate 'add' and 'delete'
        # capabilities that operate on the local model.
        # Note that the setter is supposed to accept the VALUE at the given index
        # and the getter receives the VALUE too.
        value = aModel.apply_getter(cid)
# 	tag "GOT value #{value.class} #{value}"
        key = enum2i(if value.respond_to?(:key) then value.key else value end)
#         key = key.to_i if key.respond_to?(:to_i)
#         tag "#{model}.#{cid} => value = #{value.class} #{value.inspect}, key=#{key}, index=#{@index.inspect}"
        index = @index[key]
        setCurrentIndex(index, value)
# 	tag "Check whether cid '#{cid}' is a setter (init=#{options && options[:initialize]})"

      else
#         tag "connection failure, clear the selection"
        setCurrentIndex(-1, nil)
      end
      super
    end # def connectModel
  end # class ComboBox

  createInstantiator File.basename(__FILE__, '.rb'), Qt::ComboBox, ComboBox
end
