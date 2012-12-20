
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'frame'

    class ToolBar < Frame
      include ActionContext

      private
        def text val
          @qtc.windowTitle = val
        end

      public

        #override
        def addTo parent, hash, &block
          parent.addToolbar self, hash, &block
        end

    end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::ToolBar, ToolBar

end