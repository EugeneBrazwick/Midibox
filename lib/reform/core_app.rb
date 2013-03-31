
require_relative 'r'
require_relative 'control'  

module Reform
  private # methods of Reform
    def self.app_i klass, quickyhash, &block
      klass.new.scope do |app|
	begin
	  # note that app is identical to $app
	  #tag "__FILE__ = #{__FILE__}"
	  internalize_dir '.', 'contrib' if app.load_plugins?
	  #tag "calling #{app}.setup" 
	  app.setup quickyhash, &block 
	  app.execute
	ensure
	  #tag "calling cleanup"
	  app.cleanup
	end
      end # scope
    end # app_i

  public # methods of Reform
    def self.core_app quickyhash = nil, &block
      app_i R::Qt::CoreApplication, quickyhash, &block
    end # app

end # module Reform

module R::Qt
  class CoreApplication < Control
    private # methods of CoreApplication
      def initialize 
	super
	@quit = false
	$app = self
      end

      signal :created

    public # methods of CoreApplication
      def load_plugins?; end

      def quit?; @quit; end

      def execute
	created
	exec
      end # execute

      def cleanup; end
  end
end # module R::Qt
