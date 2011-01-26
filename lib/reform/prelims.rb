
require 'shellwords'

class Prelims
    QTRUBYGEMNAME = 'qtbindings'
    PREFIX = ENV['PREFIX'] || '/usr'
    # another fine mess. If RUBY_VERSION is 1.9.2 you still need the 1.9.1 version tools
    RUBYVERSION = RUBY_VERSION == '1.9.2' ? '1.9.1' : RUBY_VERSION

    QT4BIN_REDHAT_PATH = '/usr/lib/qt4/bin'

    if File.exists?(QT4BIN_REDHAT_PATH)
      ENV['PATH'] =~ %r{/usr/lib/qt4/bin} or
	ENV['PATH'] += ':/usr/lib/qt4/bin'
    end

    # something to install
    class Package
      private
        def initialize prelims
          @prelims = prelims
        end

      public
        # base method. should install if not present.
        # should do a quick sanity test
        def check_installation
          check_reqs
        end

        # should check presense in all cases. May take more time
        def check_reqs
        end
    end

    # build the .so. This is simply done by executing rake in the current directory.
    # checks for libasound2-dev (or comparable)
    class AlsaMidiDriver < Package
      public
        def check_installation
          return unless File.exists?(File.dirname(__FILE__) + '/../rrts/driver/alsa_midi.so')
          check_reqs
          @prelims.uihandler.busy do
            `"#{@prelims.rakecmd}"`
            @prelims.uihandler.die 6, "Failed to create alsa_midi.so" unless $?.exitstatus == 0
          end
          @prelims.build_something!
        end

        def check_reqs
#       check_gem(nil, 'darkfish-rdoc', 'htmldocs', optional: true)
          @prelims.check_libdev_and_opt_apt_get('include/alsa/asoundlib.h', 'libasound2-dev', 'alsa_midi.so')
        end
    end # class AlsaMidiDriver

    class PerlinRubySo < Package
      public
        def check_installation
          return unless File.exists?(File.dirname(__FILE__) + '/../ruby-perlin/perlin.so')
          @prelims.uihandler.busy do
            `"#{@prelims.rakecmd}"`
            @prelims.uihandler.die 6, "Failed to create perlin.so" unless $?.exitstatus == 0
          end
          @prelims.build_something!
        end
    end

    class LinguisticsGem < Package
      public
        def check_reqs
          @prelims.check_gem(nil, 'linguistics', prelims.project)
        end
    end

    class Packager
      private
        def initialize prelims
          @prelims = prelims
        end

	def missing_package_critical_question package
	  @prelims.uihandler.critical_question "Package missing",
                                                "Package '#{package}' is missing but it can be " +
			   		        "installed now. Do this now?"
	end

	def geminstall package
	  @prelims.uihandler.sudo "'#{@prelims.gemcmd}' install '#{package}'" or
	    @prelims.uihandler.die(3, "Failed to install package '#{package}'")
	end

    end

    class Aptitude < Packager
      public # methods of Aptitude
	@@apt = nil
	def install file, package, target
	  @@apt ||= `which apt-get`.chomp
	  missing_package_critical_question package
	  @prelims.uihandler.sudo "'#{@@apt}' --assume-yes install '#{package}'" or
	    @prelims.uihandler.die(3, "Failed to install package '#{package}'")
	end
    end # class Aptitude

    class Yum < Packager
      public
	@@yum = nil
	def install file, package, target
	  case package
	  when 'qt4-qmake' then package = 'qt-devel'
	  when 'libqt4-dev' then package = 'qt-devel'
	  when 'libasound2-dev' then package = 'alsa-lib-devel'
	  end
	  @@yum ||= `which yum`.chomp
# 	  puts "yum = '#{@@yum}'"
	  missing_package_critical_question package
	  @prelims.uihandler.exec %Q{su -c "'#{@@yum}' --assumeyes install '#{package}'"} or
	    @prelims.uihandler.die(3, "Failed to install package '#{package}'")
	end

	def geminstall gemcmd, package # BADLY ESCAPED. IF NOT TO SAY NOT ESCAPED AT ALL...
	  puts ''
	  @prelims.uihandler.exec %Q{'#{gemcmd}' install '#{package}'} or
	    @prelims.uihandler.die(3, "Failed to install package '#{package}'")
	end
      end

    class PathologicalPacker < Packager
      public
	def install file, package, target
          @prelims.uihandlerdie 2, "There is no apt-get or yum and no '#{file}'.\n" +
			   	     "Please install #{target} by hand (and good luck...)"
	end
    end # class PathologicalPacker

    MyPackager = if `which apt-get`.chomp.empty?
		   if `which yum`.chomp.empty? then PathologicalPacker
		   else Yum
		   end
		 else Aptitude
  		 end

    class UIHandler

      public
	def die code, msg
	  STDERR.puts msg
	  exit code
	end

	def critical_question title, msg
	  ext 4 unless question title, msg
	end

	def question title, msg
	  puts msg
	  print "[Yn] "
	  gets.chomp =~ /^[Yy]|^$/
	end

	def busy
	  yield
	end

	def sudo cmd
	  `sudo #{cmd}` && $?.exitstatus == 0
	end

	def exec cmd
	  `#{cmd}` && $?.exitstatus == 0
	end

	def quit
	end

    end # class UIHandler

    class QtUIHandler < UIHandler

      private
        def  initialize
          $qApp = nil
        end

        def launch
          Qt::Application.new([]) unless $qApp
        end

      public # QtUIHandler methods

        def quit
          if $qApp
            $qApp.quit
            $qApp = nil
          end
        end

	def die code, msg
          launch
	  Qt::MessageBox::critical(nil, 'Cannot continue', msg)
	  exit code
	end

	def question title, msg
          launch
	  Qt::MessageBox::question(nil, title, msg, Qt::MessageBox::Yes | Qt::MessageBox::No,
				  Qt::MessageBox::Yes) == Qt::MessageBox::Yes
	end

	def yesno title, msg
          launch
	  Qt::MessageBox::question(nil, title, msg, Qt::MessageBox::Yes | Qt::MessageBox::No,
				  Qt::MessageBox::Yes) == Qt::MessageBox::Yes
	end

	# FIXME: it seems we need at least a single window (like a splash screen?)
	def busy
          launch
	  $qApp.overrideCursor = Qt::Cursor.new(Qt::BusyCursor)
	  yield
	ensure
	  $qApp.restoreOverrideCursor
	end

	def sudo cmd
	  STDERR.puts %Q[gksu "#{cmd}"]  # this is really nice
	  `gksu "#{cmd}"` && $?.exitstatus == 0
	end

    end # class QtUIHandler

  private # methods of Prelim

    def initialize(project, *packages)
      # the constructor should not really fail
      ENV['RUBY'] ||= 'ruby'
      @project = project
      @packager = MyPackager.new(self)
      @packages = packages.map { |packklass| packklass.new }
      @uihandler = UIHandler.new
#     puts "ASSIGNING @uihandler"
      @gemcmd = @rakecmd = nil
      @build_something = false
    end

    def check_qt_devel_present
      if File::exists?('/usr/include/Qt/qglobal.h')
	qglobal_h = '/usr/include/Qt/qglobal.h'
      else
        qtdir = ENV['QTDIR']
        qglobal_h = (qtdir ? qtdir + '/include' : 'include/qt4') + '/Qt/qglobal.h'
      end
#       STDERR.puts "!!!!!!!!!!!!!qglobal_h = '#{qglobal_h}'"
      check_libdev_and_opt_apt_get(qglobal_h, 'libqt4-dev', 'qtruby')
    end

    def aptget file, package, target
       @packager.install file, package, target
    end

    # similar to aptget, but
    #   1) there is a $qApp
    #   2) gem is present through @gemcmd
    # returns:
    # - false if user says 'no' and it is an option
    # - true if install is successfull.
    # dies if an install fails.
    def geminstall package, target, params = {}
#       STDERR.puts "geminstall missing '#{file}' critq"
      raise 'ouch' unless @gemcmd
      if params[:optional]
        return false unless @uihandler.question 'Missing jewelry',
                                                "The optional gem '#{package}' is missing, install it now?"
      else
        @uihandler.critical_question 'Missing jewelry',
                                    "Gem '#{package}' is missing but it can be installed now. Do this now?"
      end
#       STDERR.puts "BUSY?"
      @uihandler.busy do
#          STDERR.puts "gksu '#{@gemcmd}' install '#{package}'"
	@packager.geminstall @gemcmd, package
      end
      true
    end

    def check_exe_and_opt_apt_get(binary, package, target) # for example: 'gem', 'rubygems1.9.1', 'qtruby'
#       puts "check_exe_and_opt_apt_get(#{binary}, #{package}, #{target})"
#       puts "which binary -> " + `which #{binary}`
      while (cmd = `which #{binary}`.chomp).empty?
#         puts "attempt two. But a bit tricky with some binaries"
        cmd = `ls "#{PREFIX}"/bin/#{binary}* 2>/dev/null | grep '/#{binary}[0-9\.]*$' | \
               sort --general-numeric-sort | tail --lines 1`.chomp
#         puts "cmd = #{cmd.inspect}"
        return cmd unless cmd.empty?
#         puts "'#{binary}' is missing"
        # we must use apt-get to get it.
        aptget binary, package, target
      end
#       puts "RETURNING  non empty #{cmd.inspect}"
      cmd
    end

    def prelims
    # First task. Check whether the RUBY version is suitable.
      major, minor, patch = RUBYVERSION.split('.').map(&:to_i)
      if major < 1 || major == 1 && minor < 9
        # No use trying to fix this, since the ../midibox script should already have done so.
        @uihandler.die 1, "Your ruby version (#{RUBYVERSION}) is too low. 1.9.2 is required!\n" +
                          "If you have it, but $RUBY points to a lower version, please adjust $RUBY"
      end

=begin
      qtruby1.9 is a problem as apt-get qtruby will install the 1.8 version.
      Current status unknown, but it may just work if there is a 1.9 gem out there.
      Although I installed ruby1.9.1-full,  'gem' is missing!

      LOOKAHEAD?  it may be that the package is 'rubygems' and 'rubygemsXXX' may not exist.
      And may become rubygems1.9 as well if we move ahead to 1.9.3

=end
      @gemcmd = check_exe_and_opt_apt_get('gem', "rubygems#{RUBYVERSION}", 'qtruby')
      attempt = 0

      # Qt must work...
      begin
	# What goes wrong the very first time??
	raise 'gem installed OK but could not be loaded. Trying again my help' if (attempt += 1) > 3

# I got this:   /FindQt4.cmake:728 (MESSAGE): Could NOT find QtCore header
# What now?????  I linked /usr/include/qt4/Qt* right in /usr/include ....
# But why?? It never was there? How does it decide that???
# It also means you cannot put a debug version somewhere, or you have to chroot or use a virtual host.

# WHO MADE THAT CRAP CMAKE SHIT?????? HE SHOULD BE HANGED!!!!

        verb, $VERBOSE = $VERBOSE, false
        require 'Qt4'
        $VERBOSE = verb
      rescue LoadError => e
        STDERR.puts "Failed to load Qt4 (#{e.message}), attempt to build it right here and now"
        @build_something = true
=begin
  the make requires 'cmake' to be present.
=end
#         puts "Checking for cmake, CALLING check_exe_and_opt_apt_get!!!!!!!!!!!!!!"
        # check                 binary   aptpackagename  currenttarget

        ENV['CMAKE'] = check_exe_and_opt_apt_get('cmake', 'cmake', 'qtruby')
        ENV['CXX'] = check_exe_and_opt_apt_get('g++', 'g++', 'qtruby')
        ENV['QMAKE'] = check_exe_and_opt_apt_get('qmake', 'qt4-qmake', 'qtruby')
# I overlooked one somehow.  Ruby-dev is required for /usr/include/ruby/ruby.h
	if ENV['rvm_path']
	  ruby_h = ENV['rvm_path'] + '/src/' + ENV['RUBY_VERSION'] + '/include/ruby.h'
	else
	  ruby_h = "include/ruby-#{RUBYVERSION}/ruby.h"
	end
# 	puts "CHECKING '#{ruby_h}'"
        check_libdev_and_opt_apt_get(ruby_h, "ruby#{RUBYVERSION}-dev", 'qtruby')
	check_qt_devel_present
        check_gem(nil, QTRUBYGEMNAME, 'qtruby')
	gem QTRUBYGEMNAME # attempt to add the required paths?? (experimental)
        puts "Retry!"
        retry  # !
      end

=begin
  COOL, But we are not there yet

  From this moment on we can launch the qt gui.

  We must now check for
    - rake
    - rspec
    - alsa-dev stuff

But of course, if lib/rrts/driver/alsa_midi.so exists
then we can continue.
=end
      @rakecmd = check_exe_and_opt_apt_get('rake', 'CANTHAPPEN', @project)
      # We need the rspec gem first.
      ENV['RSPEC'] = check_gem('rspec', 'rspec', @project)
      @packages.each { |pack| pack.check_installation }
      @build_something
    end # def prelims

  public
    attr :uihandler, :gemcmd, :rakecmd, :project

    def check_libdev_and_opt_apt_get(incl, package, target) # for example: 't.h', 'pack-dev', 'qtruby'
      until File.exists?(incl[0] == '/' ? incl : "#{PREFIX}/#{incl}")
        STDERR.puts "#{PREFIX}/#{incl} does NOT EXIST!!!"
        aptget incl, package,target
      end
    end

    def check_installation
      prelims or return
      @uihandler = QtUIHandler.new
      if @uihandler.yesno 'Stuff was build', "Test freshly made software now?"
        `'#{@rakecmd}' test`
        @uihandler.die 7, 'rake test failed' unless $?.exitstatus == 0
      end
      @uihandler.quit
      @uihandler = @gemcmd = nil
    end # def prelims_and_spectest

    def check_gem(binary, package, target, params = {}) # for example: 'spec', 'rspec', 'project'
      unless @gemcmd
        @gemcmd = check_exe_and_opt_apt_get('gem', "rubygems#{RUBYVERSION}", @project)
      end
#       STDERR.puts "got #{@gemcmd}"
      if binary
        if (cmd = `which #{binary}`.chomp).empty?
          cmd = `ls "#{PREFIX}"/bin/#{binary}* | grep '/#{binary}[0-9\.]*$' | \
                sort --general-numeric-sort | tail --lines 1`.chomp
          return cmd unless cmd.empty?
          if geminstall package, target, params
            @uihandler.die 8, "internal error: binary #{binary} not found" if (cmd = `which #{binary}`.chomp).empty?
          end
        end
      else
        if (cmd = `#{@gemcmd} list | grep #{Shellwords::shellescape(package)}`.chomp).empty?
          if geminstall(package, target, params) &&
              (cmd = `#{@gemcmd} list | grep '#{package}'`.chomp).empty?
            @uihandler.die 8, "internal error: binary #{binary} not found" if (cmd = `which #{binary}`.chomp).empty?
          end
        end
      end
      cmd
    end

    def check_reqs
      # just a list of all checks, for debugging purposes. (use bin/midibox.rb --check-reqs)
      check_exe_and_opt_apt_get('gem', "rubygems#{RUBYVERSION}", 'qtruby')
      check_exe_and_opt_apt_get('cmake', 'cmake', 'qtruby')
      check_exe_and_opt_apt_get('g++', 'g++', 'qtruby')
      check_exe_and_opt_apt_get('qmake', 'qt4-qmake', 'qtruby')
      check_exe_and_opt_apt_get('make', 'make', 'reform') # 'make' is required for building perlin.so
      check_libdev_and_opt_apt_get("include/ruby-#{RUBYVERSION}/ruby.h", "ruby#{RUBYVERSION}-dev", 'qtruby')
      check_qt_devel_present
      check_gem(nil, QTRUBYGEMNAME, 'qtruby')
      @uihandler.quit
      @uihandler = QtUIHandler.new
      check_gem('spec', 'rspec', @project)
      @packages.each { |pack| pack.check_reqs }
    end

    def build_something!
      @build_something = true
    end
end # module Prelims

