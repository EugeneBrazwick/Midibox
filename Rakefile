
require 'rake'
require 'rake/clean'
require 'rspec/core/rake_task' # as in Upgrade.markdown
#require '/var/lib/gems/1.9.1/gems/rspec-core-2.0.1/lib/rspec/core/rake_task'
RSPEC = `gem list | grep rspec`.strip != ''
RCOV = `gem list | grep rcov`.strip != ''
RDOC = true
RGEM = false

require 'rdoc/task' if RDOC

DARKFISH = false
  # apart from that, it still says: 'Generating Darkfish...'
  # maybe rdoc already uses it if installed. That may explain why it does not work if 'required' by hand

ALSALIB='lib/rrts/driver/alsa_midi.so'
PERLINLIB='ext/ruby-perlin/perlin.so'
MIDI_IN_PORT = '20:0'
MIDI_OUT_PORT = '20:1'
RUBY = 'ruby -w -I lib'
CLEAN.include('*.o', '*.so')
CLOBBER.include('*.log')

if RDOC
  # automatically create an rdoc task, + rerdoc [+ clobber_rdoc]
  Rake::RDocTask.new do |rd|
    rd.rdoc_files.include('LICENSE', 'README', '**/*.rb', '**/*.cpp')
    rd.options << %q[--exclude="bin/|,v|Makefile|\.yaml|\.css|\.html|\.dot|\.rid|\.log"] <<
		  '--main=lib/rrts/rrts.rb' <<
		  '--title=Midibox'
    DARKFISH and rd.options << '--format=darkfish'
  end 
end # RDOC

if RSPEC
  desc "Run all rspec_test"
  RSpec::Core::RakeTask.new(:rspec_tests) do |t|
    t.rspec_opts = ['--color']
    t.ruby_opts = ['-W0']
    t.pattern = FileList['test/**/*_spec.rb', 'spec/**/*_spec.rb']
  end

  desc "Run all specs with RCov"
  RSpec::Core::RakeTask.new(:coverage) do |t|
    t.rspec_opts = ['--color']
    t.ruby_opts = ['-W0']
    t.pattern = FileList['spec/**/*_spec.rb']
    t.rcov = true
    t.rcov_opts = ['--exclude', 'spec', '--exclude', 'test']
  end

  task :test=>:rspec_tests do
 #    require 'rake/runtest'
  #  Rake.run_tests 'test/**/*_spec.rb'
  end
end # RSPEC

file ALSALIB => FileList['lib/rrts/driver/*.cpp'] do
  Dir.chdir 'lib/rrts/driver' do
    ruby './extconf.rb' 
    sh "make && rm -f *.o mkmf.log"
  end
end

file PERLINLIB => FileList['ext/ruby-perlin/*.cpp'] do
  Dir.chdir 'ext/ruby-perlin' do
    ruby './extconf.rb' 
    sh "make && rm -f *.o mkmf.log"
  end
end

file 'extsrc/miniArp'=>['extsrc/miniArp.c'] do
  sh 'cc /usr/lib/libasound.so extsrc/miniArp.c -o extsrc/miniArp -g -O0'
end

desc 'build the alsamidi shared library'
task :build_alsamidi => [ALSALIB] do
end

desc 'build the perlin shared library'
task :build_perlin => [PERLINLIB] do
end

desc 'build the ruby++ shared library'
task :build_rpp do
  Dir.chdir 'lib/ruby++' do
    ruby '-S', 'rake' 
  end
end

desc 'build the urqtCore shared library'
task :build_urqtCore do
  Dir.chdir 'lib/urqtCore' do
    ruby '-S', 'rake' 
  end
end

desc 'build the urqt shared library'
task :build_urqt do
  Dir.chdir 'lib/urqt' do
    ruby '-S', 'rake' 
  end
end

desc 'build contrib Qt objects'
task :build_contrib_Qt_libs do
  Dir.chdir 'lib/spacy_toolbutton' do
    ruby '-S', 'rake' 
  end
end

# rdoc takes far longer than anything else
desc 'build the required library bot not the documentation (use rdoc task)'
task :default => [:build_rpp, :build_urqtCore, :build_urqt, :build_contrib_Qt_libs,
		  :build_alsamidi, :build_perlin] do
end

desc 'play a track using rplaymidi++'
task :playtest do
  sh "#{RUBY} bin/rplaymidi++ --port=#{MIDI_OUT_PORT} fixtures/eurodance.midi"
end

desc 'play original miniarp'
task :play_original_miniarp => ['extsrc/miniArp'] do
  sh %q{echo 'Please use [k]aconnect to connect miniArp to year keyboard...'}
  sh %q{echo 'Press Ctrl-C to quit'}
  sh 'extsrc/miniArp 120 fixtures/miniarp.dat'
end

desc 'play rminiarp'
task :play_rminiarp do
#  sh %q{echo 'Please use [k]aconnect to connect rminiarp to year keyboard...'}
  sh %q{echo 'Press Ctrl -C to quit'}
# sorry but this only works if you have UM-2 which is questionable.
  sh "#{RUBY} bin/rminiarp --bpm=120 --wrap=UM-2 fixtures/miniarp.dat"
end

desc 'as an example to run gui examples: calculator'
task :run_calculator_example do
  `#{RUBY}  lib/reform/examples/widgets/calculator.rb`
end

desc 'as an example to run gui examples: calendar'
task :run_calendar_example do
  `#{RUBY} lib/reform/examples/widgets/calendar.rb`
end

desc 'as an example to run gui examples: charmap'
task :run_charmap_example do
  `#{RUBY} lib/reform/examples/widgets/charmap2.rb`
end

desc 'as an example to run gui examples: codeeditor'
task :run_codeeditor_example do
  `#{RUBY} lib/reform/examples/widgets/codeeditor.rb`
end

desc "panic, stop all notes on midiport #{MIDI_OUT_PORT}"
task :panic do
  sh "#{RUBY} bin/panic #{MIDI_OUT_PORT}"
end

if RGEM
  require 'rubygems/package_task'
  reform_spec = Gem::Specification.new do |spec|
    spec.name = 'reform'
    spec.summary = 'RAD gui builder, state: toy'
    spec.description = <<-EOF
	'reform' is a declarative gui builder tool, similar to 'shoes'.
	It can currenty only be used to toy around with, as the API
	is still changing heavily.
	Do not use for production stuff.
      EOF
    spec.requirements = ['qtbindings gem v4.6.3.1 or higher']
    spec.version = '0.0.0.0'
    spec.author = 'Eugene Brazwick'
    spec.email = 'eugene.brazwick@rattink.com'
    spec.homepage = 'https://github.com/EugeneBrazwick/Midibox'
    spec.platform = Gem::Platform::CURRENT # ie, my current platform, ie Linux
    spec.required_ruby_version = '>=1.9.2'
    #
    spec.files = Dir['bin/reform*', 'lib/reform/**', 'ext/ruby-perlin/**', 'Rakefile']
     # it tries to run it as ruby, but it is a bash script. There is always bin/reform
     # the handiest method is to use 'alias' like:
     #    alias reform=/var/lib/gems/1.9.1/bin/reform-0.0.0.0-x86_64-linux/bin/reform.bash
     # spec.executable = 'reform.bash'
    spec.executables = []
    spec.add_dependency 'qtbindings', '>= 4.6.3.1'
    spec.add_development_dependency 'rspec', '>=  2.0'
    spec.test_files = Dir['test/reform_spec.rb', 'test/structure_spec.rb']
    # this is completely optional. Needed in some example only.
    spec.extensions << 'ext/ruby-perlin/extconf.rb'
    spec.require_paths = ['lib', 'ext']
    spec.license = 'GPL-3'
    spec.has_rdoc = true
  end

  Rake::GemPackageTask.new(reform_spec).define	    # too old code... BROKEN
end # RGEM

