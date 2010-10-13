
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'frame'

# a Frame is a widget that may contain others.
#
# Note I changed 'containing_frame to the Qt 'parent' of the object.
# And so 'all_children' becomes simply 'children'.
# However, in the previous version a form had 'containing_frame' being the form itself.
#
# NOTE: the name clashes with Qt::Frame. This is not a Qt::Frame!!
# Use 'bordered' or 'framed' to get a Qt::Frame....
  class Splitter < Frame

#     private

#     public

  end # class Frame

  class QSplitter < Qt::Splitter
      def splitterMoved pos, index
        tag "splitterMoved(#{pos}, #{index})"
      end
  end

  createInstantiator File.basename(__FILE__, '.rb'), QSplitter, Splitter

end # Reform