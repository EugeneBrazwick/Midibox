
require_relative 'control'

module R::Qt
  class DynamicAttribute < Control
    private # methods of DynamicAttribute
      def initialize parent, klass, methodname, options, quickyhash = nil, &initblock
	#tag "DynamicAttribute.new(#{parent}, #{klass}, #{methodname})"
	super(parent) {}
	@klass, @methodname, @options = klass, methodname, options
	setup quickyhash, &initblock
      end

    public # methods of DynamicAttribute

      def apply_model data
	parent.apply_dynamic_setter @methodname, data
      end
  end
end
