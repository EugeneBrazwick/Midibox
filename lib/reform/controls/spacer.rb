
#  Copyright (c) 2010 Eugene Brazwick

module Reform

  class Spacer < Widget
    public
    def spacing v = nil
      return instance_variable_defined?(:@spacing) ? @spacing : nil unless v
      @spacing = v
    end

    alias :space :spacing
  end

  createInstantiator File.basename(__FILE__, '.rb'), nil, Spacer
end # Reform