
#  Copyright (c) 2010 Eugene Brazwick

module Reform
  require_relative 'widget'

  class GLWidget < Widget
  private

  end # class Widget

  class QGLWidget < QWidget
    public
  end # class QWidget

  createInstantiator File.basename(__FILE__, '.rb'), QGLWidget, GLWidget
end # Reform