
# Copyright (c) 2010 Eugene Brazwick

require 'reform/animation'

module Reform
  class ParallelAnimation < Animation

  end

  class QParallelAnimationGroup < Qt::ParallelAnimationGroup
    include QAnimationHackContext
  end

  createInstantiator File.basename(__FILE__, '.rb'), QParallelAnimationGroup, ParallelAnimation

end