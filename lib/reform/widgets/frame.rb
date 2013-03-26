
#  Copyright (c) 2013 Eugene Brazwick

require_relative 'widget'

module R::Qt

  ## but a border around something
  # Note that experience shows you cannot add widgets easily.
  # But you can add a layout inside it
  # 'autolayout' springs to mind
  class Frame < Widget
    public # methods of Frame
      attr_dynamic Symbol, :shadow, :shape
      attr_dynamic Fixnum, :lineWidth, :midLineWidth

      @@shadowStyles = @@shapeStyles = nil

  end # class Frame 

  class AbstractScrollArea < Frame
      attr_dynamic Symbol, :horizontalScrollBarPolicy, :verticalScrollBarPolicy
      @@scrollPolicies = nil
  end # class AbstractScrollArea

  Reform.createInstantiator __FILE__, Frame
end
