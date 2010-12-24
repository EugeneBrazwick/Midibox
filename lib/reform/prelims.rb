
require 'shellwords'

module Prelims
    QTRUBYGEMNAME = 'qtbindings'
    PREFIX = ENV['PREFIX'] || '/usr'
    # another fine mess. If RUBY_VERSION is 1.9.2 you still need the 1.9.1 version tools
    RUBYVERSION = RUBY_VERSION == '1.9.2' ? '1.9.1' : RUBY_VERSION

    QT4BIN_REDHAT_PATH = '/usr/lib/qt4/bin'
    
    if File.exists?(QT4BIN_REDHAT_PATH) 
      ENV['PATH'] =~ %r{/usr/lib/qt4/bin} or
	ENV['PATH'] += ':/usr/lib/qt4/bin'
    end

    class Packager 
      private
	def missing_package_critical_question package
	  Prelims.handler::critical_question "Package missing",
                                             "Package '#{package}' is missing but it can be " +
					     "installed now. Do this now?"
	end
	  
	def geminstall package
	  @@handler::sudo "'#{@@gemcmd}' install '#{package}'" or
	    @@handler::die(3, "Failed to install package '#{package}'")
	end

    end

    class Aptitude < Packager  
      public # methods of Aptitude
	@@apt = nil
	def install file, package, target
	  @@apt ||= `which apt-get`.chomp
	  missing_package_critical_question package
	  Prelims.handler::sudo "'#{@@apt}' --assume-yes install '#{package}'" or
	    Prelims.handler::die(3, "Failed to install package '#{package}'")
	end 
    end # class Aptitude

    class Yum < Packager
      public 
	@@yum = nil
	def install file, package, target 
	  case package
	  when 'qt4-qmake' then package = 'qt-devel'
	  when 'libqt4-dev' then package = 'qt-devel'
	  end
	  @@yum ||= `which yum`.chomp
# 	  puts "yum = '#{@@yum}'"
	  missing_package_critical_question package
	  Prelims.handler::exec %Q{su -c "'#{@@yum}' --assumeyes install '#{package}'"} or
	    Prelims.handler::die(3, "Failed to install package '#{package}'")
	end
	
	def geminstall gemcmd, package # BADLY ESCAPED. IF NOT TO SAY NOT ESCAPED AT ALL...
	  puts ''
	  Prelims::handler::exec %Q{'#{gemcmd}' install '#{package}'} or
	    Prelims::handler::die(3, "Failed to install package '#{package}'")
	end
      end
   
    class PathologicalPacker < Packager 
      public 
	def install file, package, target
          Prelims.handler::die 2, "There is no apt-get or yum and no '#{file}'.\n" +
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
	def self.die code, msg
	  STDERR.puts msg
	  exit code
	end

	def self.critical_question title, msg
	  exit 4 unless question title, msg
	end

	def self.question title, msg
	  puts msg
	  print "[Yn] "
	  gets.chomp =~ /^[Yy]|^$/
	end

	def self.busy
	  yield
	end

	def self.sudo cmd
	  `sudo #{cmd}` && $?.exitstatus == 0
	end

	def self.exec cmd
	  `#{cmd}` && $?.exitstatus == 0
	end
    end # module UIHandler

    class QtUIHandler < UIHandler

	def self.die code, msg
	  Qt::MessageBox::critical(nil, 'Cannot continue', msg)
	  exit code
	end

	def self.question title, msg
	  Qt::MessageBox::question(nil, title, msg, Qt::MessageBox::Yes | Qt::MessageBox::No,
				  Qt::MessageBox::Yes) == Qt::MessageBox::Yes
	end

	def self.yesno title, msg
	  Qt::MessageBox::question(nil, title, msg, Qt::MessageBox::Yes | Qt::MessageBox::No,
				  Qt::MessageBox::Yes) == Qt::MessageBox::Yes
	end

	# FIXME: it seems we need at least a single window (like a splash screen?)
	def self.busy
	  $qApp.overrideCursor = Qt::Cursor.new(Qt::BusyCursor)
	  yield
	ensure
	  $qApp.restoreOverrideCursor
	end

	def self.sudo cmd
	  STDERR.puts %Q[gksu "#{cmd}"]  # this is really nice
	  `gksu "#{cmd}"` && $?.exitstatus == 0
	end

    end # class QtUIHandler

    # the constructor should not really fail
    @@packager = MyPackager.new
    @@handler = UIHandler
#     puts "ASSIGNING @@handler"
    @@gemcmd = @@rakecmd = nil
    @@build_something = false

  private # methods of Prelim

    def self.check_qt_devel_present
      if File::exists?('/usr/include/Qt/qglobal.h')
	qglobal_h = '/usr/include/Qt/qglobal.h'
      else
        qtdir = ENV['QTDIR']
        qglobal_h = (qtdir ? qtdir + '/include' : 'include/qt4') + '/Qt/qglobal.h'
      end
#       STDERR.puts "!!!!!!!!!!!!!qglobal_h = '#{qglobal_h}'"
      check_libdev_and_opt_apt_get(qglobal_h, 'libqt4-dev', 'qtruby')
    end
    
    def self.aptget file, package, target
       @@packager.install file, package, target 
    end

    # similar to aptget, but
    #   1) there is a $qApp
    #   2) gem is present through @@gemcmd
    # returns:
    # - false if user says 'no' and it is an option
    # - true if install is successfull.
    # dies if an install fails.
    def self.geminstall package, target, params = {}
#       STDERR.puts "geminstall missing '#{file}' critq"
      raise 'ouch' unless @@gemcmd
      if params[:optional]
        return false unless @@handler::question 'Missing jewelry',
                                                "The optional gem '#{package}' is missing, install it now?"
      else
        @@handler::critical_question 'Missing jewelry',
                                    "Gem '#{package}' is missing but it can be installed now. Do this now?"
      end
#       STDERR.puts "BUSY?"
      @@handler::busy do
#          STDERR.puts "gksu '#{@@gemcmd}' install '#{package}'"
	@@packager.geminstall @@gemcmd, package 
      end
      true
    end

    def self.check_libdev_and_opt_apt_get(incl, package, target) # for example: 't.h', 'pack-dev', 'qtruby'
      until File.exists?(incl[0] == '/' ? incl : "#{PREFIX}/#{incl}")
        STDERR.puts "#{PREFIX}/#{incl} does NOT EXIST!!!"
        aptget incl, package,target
      end
    end

    def self.check_exe_and_opt_apt_get(binary, package, target) # for example: 'gem', 'rubygems1.9.1', 'qtruby'
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

    def self.prelims
    # First task. Check whether the RUBY version is suitable.
      major, minor, patch = RUBYVERSION.split('.').map(&:to_i)
      if major < 1 || major == 1 && minor < 9
        # No use trying to fix this, since the ../midibox script should already have done so.
        @@handler::die 1, "Your ruby version (#{RUBYVERSION}) is too low. 1.9 is required!\n" +
                          "If you have it, but $RUBY points to a lower version, please adjust $RUBY"
      end

=begin
      qtruby1.9 is a problem as apt-get qtruby will install the 1.8 version.
      Current status unknown, but it may just work if there is a 1.9 gem out there.
      Although I installed ruby1.9.1-full,  'gem' is missing!

      LOOKAHEAD?  it may be that the package is 'rubygems' and 'rubygemsXXX' may not exist.
      And may become rubygems1.9 as well if we move ahead to 1.9.3

=end
      @@gemcmd = check_exe_and_opt_apt_get('gem', "rubygems#{RUBYVERSION}", 'qtruby')

      # Qt must work...
      begin
# I got this:   /FindQt4.cmake:728 (MESSAGE): Could NOT find QtCore header
# What now?????  I linked /usr/include/qt4/Qt* right in /usr/include ....
# But why?? It never was there? How does it decide that???
# It also means you cannot put a debug version somewhere, or you have to chroot or use a virtual host.

# WHO MADE THAT CRAP CMAKE SHIT?????? HE SHOULD BE HANGED!!!!

        verb, $VERBOSE = $VERBOSE, false
        require 'Qt4'
        $VERBOSE = verb
      rescue LoadError
        STDERR.puts "Failed to load Qt4, attempt to build it right here and now"
        @@build_something = true
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
	puts "CHECKING '#{ruby_h}'"
        check_libdev_and_opt_apt_get(ruby_h, "ruby#{RUBYVERSION}-dev", 'qtruby')
	check_qt_devel_present
        check_gem(nil, QTRUBYGEMNAME, 'qtruby')
        puts "Retry!"
        retry  # !
      end

=begin
  COOL, But we are not there yet

  We must now check for
    - rake
    - rspec
    - alsa-dev stuff

But of course, if lib/rrts/driver/alsa_midi.so exists
then we can continue
=end
      unless File.exists?(File.dirname(__FILE__) + '/../rrts/driver/alsa_midi.so')
#         STDERR.puts "alsa_midi.so does not exist (FILE=#{__FILE__})"
        @@build_something = true
        Qt::Application.new([]) unless $qApp
        @@handler = QtUIHandler
        # rake is part of the 'ruby' core package. But let's get the correct version.
        @@rakecmd = check_exe_and_opt_apt_get('rake', 'CANTHAPPEN', 'alsa_midi.so')
        # We need the rspec gem first.
        ENV['RSPEC'] = check_gem('rspec', 'rspec', 'alsa_midi.so')
#         check_gem(nil, 'darkfish-rdoc', 'htmldocs', optional: true)
#         check_gem(nil, 'shoulda', 'testing', optional: true)          no longer used
        check_libdev_and_opt_apt_get('include/alsa/asoundlib.h', 'libasound2-dev', 'alsa_midi.so')
        @@handler::busy do
          `"#{@@rakecmd}"`
          @@handler::die 6, "Failed to create alsa_midi.so" unless $?.exitstatus == 0
        end
      end
      @@build_something
    end # def prelims

  public
    def self.prelims_and_spectest
      $qApp = nil
      prelims or return
      @@handler = QtUIHandler
      Qt::Application.new([]) unless $qApp
      if @@handler::yesno 'Stuff was build', "Test freshly made software now?"
        `'#{@@rakecmd}' test`
        @@handler::die 7, 'rake test failed' unless $?.exitstatus == 0
      end
      if $qApp
        $qApp.quit
        $qApp = nil
      end
      @@handler = @@gemcmd = nil
    end # def prelims_and_spectest

    def self.check_gem(binary, package, target, params = {}) # for example: 'spec', 'rspec', 'project'
      @@handler = QtUIHandler if $qApp
      unless @@gemcmd
        @@gemcmd = check_exe_and_opt_apt_get('gem', "rubygems#{RUBYVERSION}", 'midibox')
      end
#       STDERR.puts "got #{@@gemcmd}"
      if binary
        if (cmd = `which #{binary}`.chomp).empty?
          cmd = `ls "#{PREFIX}"/bin/#{binary}* | grep '/#{binary}[0-9\.]*$' | \
                sort --general-numeric-sort | tail --lines 1`.chomp
          return cmd unless cmd.empty?
          if geminstall package, target, params
            @@handler::die 8, "internal error: binary #{binary} not found" if (cmd = `which #{binary}`.chomp).empty?
          end
        end
      else
        if (cmd = `#{@@gemcmd} list | grep #{Shellwords::shellescape(package)}`.chomp).empty?
          if geminstall(package, target, params) &&
              (cmd = `#{@@gemcmd} list | grep '#{package}'`.chomp).empty?
            @@handler::die 8, "internal error: binary #{binary} not found" if (cmd = `which #{binary}`.chomp).empty?
          end
        end
      end
      cmd
    end

    def self.handler
      @@handler
    end
    
    def self.check_reqs
      # just a list of all checks, for debugging purposes. (use bin/midibox.rb --check-reqs)
      check_exe_and_opt_apt_get('gem', "rubygems#{RUBYVERSION}", 'qtruby')
      check_exe_and_opt_apt_get('cmake', 'cmake', 'qtruby')
      check_exe_and_opt_apt_get('g++', 'g++', 'qtruby')
      check_exe_and_opt_apt_get('qmake', 'qt4-qmake', 'qtruby')
      check_libdev_and_opt_apt_get("include/ruby-#{RUBYVERSION}/ruby.h", "ruby#{RUBYVERSION}-dev", 'qtruby')
      check_qt_devel_present
      check_gem(nil, QTRUBYGEMNAME, 'qtruby')
      check_gem('spec', 'rspec', 'alsa_midi.so')
#       check_gem(nil, 'darkfish-rdoc', 'htmldocs', optional: true)
      check_libdev_and_opt_apt_get('include/alsa/asoundlib.h', 'libasound2-dev', 'alsa_midi.so')
      check_gem(nil, 'linguistics', 'midibox')
    end
end # module Prelims

