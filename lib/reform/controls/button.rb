
# Copyright (c) 2010 Eugene Brazwick

module Reform

  class Button < Widget
    private
    define_simple_setter :text

    public

    # with a block associate the block with the 'clicked' signal.
    # Without a block we emit 'clicked'
    def whenClicked &block
      if block
        connect(@qtc, SIGNAL('clicked()'), self) { rfCallBlockBack(&block) }
      else
        @qtc.clicked
      end
    end #whenClicked

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::PushButton, Button

end # Reform