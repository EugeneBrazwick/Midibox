
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'checkbox'

  class RadioButton < CheckBox

    private
    def initialize parent, qtc
      super(parent, qtc, false)
      @value = 0
      connect(@qtc, SIGNAL('clicked(bool)'), self) do |checked|
        rfRescue { model.apply_setter(cid, @value) if cid = connector && model = effectiveModel }
      end
    end

    def value v
      @value = v
    end

    public
    def connectModel aModel, options = nil
      cid = connector or return
      if @model && @model.getter?(cid)
        @qtc.checked = @value == @model.apply_getter(cid)
      else
        @qtc.checked = false
      end
      whenConnected aModel
    end

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::RadioButton, RadioButton

end # module Reform