
# this really is a contrib 'model'. Should we make it a directory? Or match 'model'
# in the contrib directory ???
module Reform

  require_relative '../model'

  # I think Control is too heavy as a parent FIXME
  class IconExampleEntry < Qt::Object
    include Model
    # We have 3 attributes 'name', 'mode', 'state'
    # name is the filename. An entry can only exist if loaded from a file
    # Each entry matches a single row in a Table
    # and each attribute matches a single 'item' of the appropriate column of the table
    private
    def initialize filename
      super()
      tag "new IconExampleEntry"
      @filename = filename
      @name = File.basename(filename)
      @checked = true
      @mode = tr('Normal')
      @state = tr('Off')
    end

    def available_modes
      [tr('Normal'), tr('Active'), tr('Disabled'), tr('Selected')]
    end

    def available_states
      [tr('Off'), tr('On')]
    end

    public

    dynamic_accessor :mode, :state, :checked?
    attr :filename, :name
  end

  # I think Control is too heavy as a parent FIXME
  class IconExampleModel < Control
    include Model

    private
    def initialize parent, qtc
#       tag("New IconExampleModel")
      super
      @icons = []
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

    def each &block
      @icons.each(&block)
    end

    def length
      @icons.length
    end
  end

  createInstantiator File.basename(__FILE__, '.rb'), nil, IconExampleModel

end