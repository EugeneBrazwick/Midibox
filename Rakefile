
require 'rake/clean'
require 'rake/rdoctask'
require 'spec/rake/spectask'

ALSALIB='lib/rrts/driver/alsa_midi.so'
MIDI_IN_PORT = '20:0'
MIDI_OUT_PORT = '20:1'
RUBY = 'ruby -w -I lib'
CLEAN.include('*.o', '*.so')
CLOBBER.include('*.log')

# automatically create an rdoc task, + rerdoc [+ clobber_rdoc]
Rake::RDocTask.new do |rd|
  rd.main = 'lib/rrts/rrts.rb'
  rd.rdoc_files.include('LICENSE', 'README', '**/*.rb', '**/*.cpp')
  rd.title = 'Midibox'
  rd.options << '--line-numbers' <<
                %q[--exclude="bin/|,v|Makefile|\.yaml|\.css|\.html|\.dot|\.rid|\.log"]
    #ALTERNATIVES: --inline-source --fileboxes --diagram
end

desc "Run all rspec_test"
Spec::Rake::SpecTask.new(:rspec_tests) do |t|
  t.spec_files = FileList['test/**/*_spec.rb']
end

task :test=>:rspec_tests do
  require 'rake/runtest'
  Rake.run_tests 'test/ts_*.rb'
end

file ALSALIB => FileList['lib/rrts/driver/*.cpp'] do
  Dir.chdir 'lib/rrts/driver' do
    sh 'ruby ./extruby.rb && make'
  end
end

file 'extsrc/miniArp'=>['extsrc/miniArp.c'] do
  sh 'cc /usr/lib/libasound.so extsrc/miniArp.c -o extsrc/miniArp -g -O0'
end

desc 'build the alsamidi shared library'
task :build_alsamidi => [ALSALIB] do
end

desc 'build the required library and the documentation'
task :default => [:build_alsamidi, :rdoc] do
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

desc 'panic, stop all notes on midipot 20:1'
task :panic do
  sh "#{RUBY} bin/panic 20:1"
end

