
require_relative '../graphicsitem'

module R::Qt
  # inconvenient 'pos' of topleft, where I expect center.
  # also GraphicsItems are NOT QGraphicsItems. Because they are QObjects...
  class Circle_TopLeft < GraphicsItem
    public # methods of Circle_TopLeft
      attr_dynamic 
  end 

  Reform.createInstantiator __FILE__, Circle_TopLeft
end
