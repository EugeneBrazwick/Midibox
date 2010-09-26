
# Copyright (c) 2010 Eugene Brazwick

require 'reform/animation'

module Reform
  class SequentialAnimation < Animation
    private
      def pause duration_in_ms = 250
        @qtc.addPause duration_in_ms
      end
  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::SequentialAnimationGroup, SequentialAnimation

end