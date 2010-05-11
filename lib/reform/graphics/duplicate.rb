
# tag "loading duplicate.rb"
module Reform

  # this is not even a widget, but it can be nested
  class Duplicate < Control
    # make it possible to add both widgets and graphicitems, but delay creation.
    # just 'can' it.
    include ScenePanelMacroContext
  private
    def initialize panel, qtc
      super
      @transform = Qt::Transform.new
      @count = nil # unset
      @rotation = nil
      @fillhue = nil
    end

    # note that floats between -1.0 and 1.0 are seen as a fraction of a 360 degree rotation.
    # So rotate 180 == rotate 180.0 == rotate 0.5
    # The rotation is clockwise
    def rotation degrees
      degrees *= 360.0 unless Integer === degrees || degrees.abs > 1.00000001
      @rotation ||= 0.0
      @rotation += degrees
      @transform.rotate degrees
    end

    def count c = nil
      return @count unless c
      @count = c
    end

    def scale factor
      @transform.scale factor
    end

    def translation x, y
      @transform.translate x, y
    end

    def fillhue step = nil
      return @fillhue unless step
      @fillhue = step
    end

    # override
    def executeMacros
      tag "executeMacros macros=#{@macros.inspect}"
#       @macros and @macros.each { |macro| macro.exec }
    end

  end # class Duplicate

#   tag "createInstantiator for duplicate"
  # there is no implementor.
  createInstantiator File.basename(__FILE__, '.rb'), nil, Duplicate

end