
require 'rake/clean'
require 'rake/rdoctask'

ALSALIB='lib/rrts/driver/alsa_midi.so'
MIDI_IN_PORT = '20:0'
MIDI_OUT_PORT = '20:1'

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

# there aren't yet....
task :test do
  require 'rake/runtest'
  Rake.run_tests 'test**/**Test.rb'
end

file ALSALIB => FileList['lib/rrts/driver/*.cpp'] do
  Dir.chdir 'lib/rrts/driver' do
    sh 'ruby ./extruby.rb && make'
  end
end

desc 'build the alsamidi shared library'
task :build_alsamidi => [ALSALIB] do
end

desc 'build the required library and the documentation'
task :default => [:build_alsamidi, :rdoc] do
end

desc 'play a track using rplaymidi++'
task :playtest do
  sh "ruby -w -I lib bin/rplaymidi++ --port=#{MIDI_OUT_PORT} fixtures/eurodance.midi"
end
