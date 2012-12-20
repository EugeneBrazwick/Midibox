
# Copyright (c) 2010 Eugene Brazwick

require 'reform/abstractstate'

module Reform
  class State < AbstractState

  end

  createInstantiator File.basename(__FILE__, '.rb'), QState, State

end