
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../abstractbutton'

  class ToolButton < AbstractButton
    private

      define_simple_setter :iconSize

      def icon anIcon
        self.icon = anIcon
      end

    public

      # added support for qt images, files, an pixmaps
      def icon= anIcon
        anIcon = Qt::Icon.new(anIcon.to_str) if anIcon.respond_to?(:to_str)
        anIcon = Qt::Pixmap::fromImage(anIcon) if Qt::Image === anIcon
        anIcon = Qt::Icon.new(anIcon) if Qt::Pixmap === anIcon
#         tag "#@qtc.icon := #{anIcon}"
        @qtc.icon = anIcon
      end

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::ToolButton, ToolButton

end # Reform