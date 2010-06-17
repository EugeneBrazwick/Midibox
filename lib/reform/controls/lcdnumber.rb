
#  Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'widget'

  class LCDNumber < Widget
    private

    define_simple_setter :segmentStyle

    def flat v = true
      segmentStyle Qt::LCDNumber::Flat
    end

    def outlined v = true
      segmentStyle Qt::LCDNumber::Outline
    end

    def sizeHint x, y = nil
      @qtc.size = y ? Qt::Size.new(x, y) : Qt::Size.new(*x)
    end


   public

    #override
    def updateModel model, options = nil
#       tag "updateModel #{model.inspect}, cid=#{connector}"
      cid = connector or return
      if model && model.getter?(cid)
#         tag "getter located"
        time = model.apply_getter(cid)
        # this should be a Qt::Time
        @qtc.display time.toString(if time.second % 2 == 0 then 'hh mm' else 'hh:mm' end)
      else
        @qtc.display 0
      end
      super
    end

  end # class LCDNumber

  class QLCDNumber < Qt::LCDNumber
    attr_accessor :size
    def sizeHint
      size || super
    end
  end

  createInstantiator File.basename(__FILE__, '.rb'), QLCDNumber, LCDNumber
end # Reform