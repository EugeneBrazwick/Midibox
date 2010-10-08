
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../controls/button'

  class QSpacyToolButton < Qt::ToolButton

    private
    def initialize parent = nil
      super
#       tag "setSizePolicy"
      setSizePolicy Qt::SizePolicy::Expanding, Qt::SizePolicy::Preferred
    end

    public
    def sizeHint
      size = super
      size.height += 20
      size.width = [size.width, size.height].max
#       tag "sizeHint -> #{size.inspect}"
      size
    end
  end

  createInstantiator File.basename(__FILE__, '.rb'), QSpacyToolButton, Button

end # Reform