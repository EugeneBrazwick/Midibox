
#  Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../labeledwidget'

  class ComboBox < LabeledWidget
    include ModelContext
    private

    def initialize parent, qtc
      super
      @index = {}
      @data = []
    end

    # connector is the 'local' connector, that connects to the local 'model'
    # and if set is applied as 'getter' to fetch the strings to add to the combobox
    def local_connector sym
      @connector = sym
    end

    def currentKey k
#       tag "currentKey := #{k.class}#{k}, index=#{@index.inspect}, index[k]=#{@index[k]}"
      k = k.to_i if k.respond_to?(:to_i)  # this fixes Qt::Enum identity crises (I hope)
      @qtc.currentIndex = @index[k] || -1
#       tag "currentIndex is now #{@qtc.currentIndex}"
    end

    # data can be array, hash, or any ruby object that includes Model or ActiveSOMETHING(niy)
    # and also Enumerable.
    def model *data
      # storing data in the combobox using Qt::Variant is very tricky.
      # since storing objid may dispose of the ruby object, as it is no longer
      # referenced. So we build a hash here, using key if possible, and the value
      # will be the index in the combobox. So findData can be implemented easily enough
      # luckely a single string is not an enumerable, and has no 'each' either.
      @index = {}
      # however, the key is not good enough. Adding the actual contents here:
      @data = []
      # However, this duplicates the data passed to the combo, which seems a waste.
      # What about @data = data ??
      data = data[0] if data.length == 1 && data[0].respond_to?(:each)
      # assigning data like this should provide that @objhash[combo.itemdata] is the value
      # However, Qt::Enum may be problematic
#       @objhash = data
      # comboboxes may have virtual contents. In that case use virtualcombo.
      # we use abuse datasource and copy it completely into Qt format.
      contor = instance_variable_defined?(:@connector) && @connector || :to_s
      if data.respond_to? :each_pair
#         tag "data responds to 'each_pair'"
        i = 0
        data.each_pair do |k, obj|
          key = k.respond_to?(:key) ? k.key : k
          key = key.to_i if key.respond_to?(:to_i)  # this fixes Qt::Enum identity crises (I hope)
          @index[key] = i
#           tag "addItem(#{obj}, #{key.inspect}, keyclass=#{key.class})"
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
          key = obj.respond_to?(:key) ? obj.key : obj
          key = key.to_i if key.respond_to?(:to_i)  # this fixes Qt::Enum identity crises (I hope)
#           tag "@index[#{key.class}#{key}] := #{j}"
          @index[key] = j
          @data << obj
          @qtc.addItem(obj.respond_to?(:to_str) ? obj.to_str : obj.send(contor))
        end
      end
#       tag "created index #{@index.inspect}, and data #{@data.inspect}"
    end

    define_simple_setter :currentIndex

    public

    def whenActivated&block
      if block
        connect(@qtc, SIGNAL('activated(int)'), self) do |idx|
          rfCallBlockBack(@data[idx], idx, &block)
        end
      else
        @qtc.activated(@qtc.currentIndex)
      end
    end #whenActivated

    def setModel model, &block
      @model.removeObserver_i(self) if instance_variable_defined?(:@model)
      @model = model
      if @model
#         @model.containing_form = @containing_form
        @model.instance_eval(&block) if block
        @model.postSetup
        @model.addObserver_i self
        model @model
        connectModel(@model, initialize: true) # if instance_variable_defined?(:@model)
      end
    end

    #override
    def connectModel model, options = nil
#       tag "connectModel #{model}, cid='#{connector}',options=#{options.inspect}"
      cid = connector or return
      if model && model.getter?(cid)
#         tag "getter '#{cid}' located"
        # it's not entirely clear when the events are triggered
        # - currentIndexChanged(int)
        # - currentIndexChanged(string)
        # - editTextChanged(string). Must 'editable' be true for this??
        # It should be possible to make a combobox with immediate 'add' and 'delete'
        # capabilities that operate on the local model.
        # Note that the setter is supposed to accept the VALUE at the given index
        # and the getter receives the VALUE too.
        value = model.apply_getter(cid)
        key = if value.respond_to?(:key) then value.key else value end
        key = key.to_i if key.respond_to?(:to_i)
#         tag "#{model}.#{cid} => value = #{value.class} #{value.inspect}, key=#{key}, index=#{@index[key]}"
        index = @index[key]
        @qtc.currentIndex = index
        if model.setter?(cid) && options && options[:initialize]
          # note activated is only called from user interaction, not from the setter above
          # and that is just what is required
          connect(@qtc, SIGNAL('activated(int)'), self) do |idx|
            # index can also be -1 (let the value be nil)
#             tag "activated combobox (i=#{idx}), name=#{name}"
#             var = idx >= 0 ? @qtc.itemData(idx) : nil
#             tag "activated idx -> #{idx}, itemData(#{idx}) = #{var.inspect}"
            var = @data[idx]
            model.send(cid + '=', @data[idx])
          end
        elsif options && options[:initialize]
#           @qtc.readOnly = true
          # how to do this ??? TODO, it should be possible to set the combo to a single, fixed value....
        end
      else
#         tag "connection failure, clear the selection"
        @qtc.currentIndex = -1
      end
      super
    end # def connectModel
  end # class ComboBox

  createInstantiator File.basename(__FILE__, '.rb'), Qt::ComboBox, ComboBox
end
