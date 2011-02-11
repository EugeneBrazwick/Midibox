
# Copyright (c) 2011 Eugene Brazwick

module Reform

require 'reform/control'
require 'reform/app'

  class GraphicsEffect < Control
    private

    public
      def self.parent_qtc parent_control, parent_effective_qtc
        parent_control
      end

      def addTo parent, quickyhash, &block
        setup quickyhash, &block
        parent.qtc.graphicsEffect = @qtc
#        added control
      end
  end # class GraphicsEffect

end # Module Reform