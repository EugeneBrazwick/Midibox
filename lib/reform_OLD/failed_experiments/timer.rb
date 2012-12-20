
# Copyright (c) 2010 Eugene Brazwick

module Reform

  class Timer < Control
    private

    define_simple_setter :interval

    public

    def timer?
      true
    end
  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::Timer, Timer

end # Reform