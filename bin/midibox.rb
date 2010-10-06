#!/usr/bin/ruby

# Copyright (c) 2010 Eugene Brazwick
# verified with clean Ubuntu version on Oct 2 2010.
# However some backtracking was done.

=begin
This shellscript installs all midibox required software and then
launches the real program which is ../gui/mainform.rb

CONTEXT:   ../midibox.          This shellscript tries to set $RUBY, then calls us.

The philosophy is this: it should just work!
So I assume nothing yet.

PACKAGELIST:

  DEBS: ruby1.9.1-full rubygems  cmake g++ qt4-qmake libqt4-dev libasound2-dev
  GEMS: qtbindings rspec

OPTIONS:
  GEMS: darkfish-rdoc

===ruby1.9.2
Not the current Ubuntu version, if installed with a reasonable 'configure' then
the gemdir changes into /usr/lib/ruby/gems, iso /var/lib/gems.
As a result, all gems disappear and are rebuild, if you don't take precautions.
I'm alsa getting this error now:
 Linking CXX shared library libqtruby4shared.so
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/4.4.3/../../../../lib/libruby-static.a(array.o): relocation R_X86_64_32 against `.rodata.str1.1' can not be used when making a shared object; recompile with -fPIC
/usr/lib/gcc/x86_64-linux-gnu/4.4.3/../../../../lib/libruby-static.a: could not read symbols: Bad value
collect2: ld returned 1 exit status
make[3]: *** [ruby/qtruby/src/libqtruby4shared.so.2.0.0] Error 1
Bad linking flags???? No that stupid configure never built any .so's..... WTF?
./configure --prefix=/usr --exec-prefix=/usr --localstatedir=/var --sysconfdir=/etc --enable-shared

=end
module Prelims
    QTRUBYGEMNAME = 'qtbindings'
    PREFIX = ENV['PREFIX'] || '/usr'
    # another fine mess. If RUBY_VERSION is 1.9.2 you still need the 1.9.1 version tools
    RUBYVERSION = RUBY_VERSION == '1.9.2' ? '1.9.1' : RUBY_VERSION

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
#         STDERR.puts %Q[gksu "#{cmd}"]
        `gksu "#{cmd}"` && $?.exitstatus == 0
      end

    end

    @@handler = UIHandler
    @@gemcmd = @@rakecmd = nil
    @@build_something = false

  private

    def self.aptget file, package, target
      (aptgetcmd = `which apt-get`.chomp).empty? and
        @@handler::die 2, "There is no apt-get and no '#{file}'.\n" +
                          "Please install #{target} by hand (and good luck...)"
      @@handler::critical_question "Package missing",
                                   "Package '#{package}' is missing but it can be installed now. Do this now?"
      @@handler::sudo "'#{aptgetcmd}' --assume-yes install '#{package}'" or
        @@handler::die(3, "Failed to install package '#{package}'")
    end

    # similar to aptget, but
    #   1) there is a $qApp
    #   2) gem is present through @@gemcmd
    # returns false if user says 'no' and it is en option
    def self.geminstall package, target, params = {}
#       STDERR.puts "geminstall missing '#{file}' critq"
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
        @@handler::sudo "'#{@@gemcmd}' install '#{package}'" or
          @@handler::die(3, "Failed to install package '#{package}'")
      end
      true
    end

    def self.check_libdev_and_opt_apt_get(incl, package, target) # for example: 't.h', 'pack-dev', 'qtruby'
      until File.exists?("#{PREFIX}/#{incl}")
#         STDERR.puts "#{PREFIX}/#{incl} does NOT EXIST!!!"
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

    def self.check_gem(binary, package, target, params = {}) # for example: 'spec', 'rspec', 'project'
      if binary
        while (cmd = `which #{binary}`.chomp).empty?
          cmd = `ls "#{PREFIX}"/bin/#{binary}* | grep '/#{binary}[0-9\.]*$' | \
                sort --general-numeric-sort | tail --lines 1`.chomp
          return cmd unless cmd.empty?
          geminstall package, target, params or break
        end
      else
        while (cmd = `gem list | grep '#{package}'`.chomp).empty?
          geminstall package, target, params or break
        end
      end
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
        verb, $VERBOSE = $VERBOSE, false
        require 'Qt4'
        $VERBOSE = verb
      rescue LoadError
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
        check_libdev_and_opt_apt_get("include/ruby-#{RUBYVERSION}/ruby.h", "ruby#{RUBYVERSION}-dev", 'qtruby')
        check_libdev_and_opt_apt_get('include/qt4/Qt/qglobal.h', 'libqt4-dev', 'qtruby')
        check_gem(nil, QTRUBYGEMNAME, 'qtruby')
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
      unless File.exists?(File.dirname(__FILE__) + '/../lib/rrts/driver/alsa_midi.so')
#         STDERR.puts "alsa_midi.so does not exist"
        @@build_something = true
        Qt::Application.new([]) unless $qApp
        @@handler = QtUIHandler
        # rake is part of the 'ruby' core package. But let's get the correct version.
        @@rakecmd = check_exe_and_opt_apt_get('rake', 'CANTHAPPEN', 'alsa_midi.so')
        # We need the rspec gem first.
        ENV['RSPEC'] = check_gem('spec', 'rspec', 'alsa_midi.so')
        check_gem(nil, 'darkfish-rdoc', 'htmldocs', optional: true)
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

    def self.check_reqs
      # just a list of all checks, for debugging purposes. (use bin/midibox.rb --check-reqs)
      check_exe_and_opt_apt_get('gem', "rubygems#{RUBYVERSION}", 'qtruby')
      check_exe_and_opt_apt_get('cmake', 'cmake', 'qtruby')
      check_exe_and_opt_apt_get('g++', 'g++', 'qtruby')
      check_exe_and_opt_apt_get('qmake', 'qt4-qmake', 'qtruby')
      check_libdev_and_opt_apt_get("include/ruby-#{RUBYVERSION}/ruby.h", "ruby#{RUBYVERSION}-dev", 'qtruby')
      check_libdev_and_opt_apt_get('include/qt4/Qt/qglobal.h', 'libqt4-dev', 'qtruby')
      check_gem(nil, QTRUBYGEMNAME, 'qtruby')
      check_gem('spec', 'rspec', 'alsa_midi.so')
      check_gem(nil, 'darkfish-rdoc', 'htmldocs', optional: true)
      check_libdev_and_opt_apt_get('include/alsa/asoundlib.h', 'libasound2-dev', 'alsa_midi.so')
    end
end # module Prelims

if ARGV[0] == '--check-reqs'
  ARGV.shift
  # This takes too long for a normal jumpstart. But if you miss some optional stuff
  # it could be usefull.
  Prelims::check_reqs
else
  Prelims::prelims_and_spectest
  # It is also tempting to say `exec $RUBY $PWD/gui/mainform.rb &`
  # Otherwise we get a stuck terminal.... So:
  ENV['RUBY'] ||= 'ruby'
  spawn "$RUBY '#{File.dirname(__FILE__)}/../gui/mainform.rb'"
end