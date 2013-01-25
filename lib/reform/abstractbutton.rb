
#  Copyright (c) 2013 Eugene Brazwick

require_relative 'widgets/widget'

module R::Qt
  class AbstractButton < Widget 
    public # methods of AbstractButton
      attr_dynamic String, :text
  end # class AbstractButton
end # module Qt

