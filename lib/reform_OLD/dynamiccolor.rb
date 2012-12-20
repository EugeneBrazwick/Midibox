
module Reform

  require_relative 'dynamicattribute'

  # A new pattern is emerging here!
  class DynamicColor < DynamicAttribute
    private

      # currently floats are not supported (yet). Cannot be that hard
      define_setters Integer, :red, :green, :blue, :alpha

    public

      def_acceptors :red, :green, :blue, :alpha

  end # DynamicColor

  class DynamicPoint < DynamicAttribute
    private

      define_setters Float, :x, :y

    public

      def_acceptors :x, :y

  end # DynamicColor

end # Reform
