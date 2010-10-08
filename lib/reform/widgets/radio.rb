
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'checkbox'

  class RadioButton < CheckBox

    private
    def initialize parent, qtc
      super(parent, qtc, false)
      @value = 0
      connect(@qtc, SIGNAL('clicked(bool)'), self) do |checked|
        rfRescue do
          if (cid = connector) && (model = effectiveModel)
            model.apply_setter(cid, @value)
          end
        end
      end
    end

    # override
    def value v = nil
      return @value if v.nil?
      @value = v
    end

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::RadioButton, RadioButton

end # module Reform