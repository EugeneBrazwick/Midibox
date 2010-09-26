
# Copyright (c) 2010 Eugene Brazwick

require 'reform/animation'

module Reform
  class ParallelAnimation < Animation

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::ParallelAnimationGroup, ParallelAnimation

end