# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'frame'

  class GroupBox < Frame
    private
    define_simple_setter :title, :checkable, :checked, :flat
  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::GroupBox, GroupBox

end

