
# this really is a contrib 'model'. Should we make it a directory? Or match 'model'
# in the contrib directory ???
module Reform

  require_relative '../model'

  class IconExampleModel < Control
    include Model

    private
    def initialize parent, qtc
#       tag("New IconExampleModel")
      super
    end

    public
    # sets the style, but also the GLOBAL Qt style!!
    def style= stylefactoryname
#       tag "style := #{stylefactoryname}"
      @stylefactoryname = stylefactoryname
      @style = Qt::StyleFactory::create(@stylefactoryname)
      Qt::Application::style = @style
      dynamic_property_changed :style
    end

    def metric= m
#       tag "metric:= #{m}, causes extent to change"
      @metric = m
      self.extent = Qt::Application::style.pixelMetric(m)
    end

    dynamic_accessor :extent
    attr :metric
  end

  createInstantiator File.basename(__FILE__, '.rb'), nil, IconExampleModel

end