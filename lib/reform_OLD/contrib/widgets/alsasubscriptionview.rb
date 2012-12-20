
require 'reform/widgets/canvas'

module Reform
  class AlsaSubscriptionView < Canvas
  end

  createInstantiator File.basename(__FILE__, '.rb'), QGraphicsView, AlsaSubscriptionView

end