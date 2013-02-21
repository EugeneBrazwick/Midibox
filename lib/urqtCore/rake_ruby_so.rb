
require 'rake/clean'
require 'shellwords'

module R
  module Ake; end
end

# NOTE: apparently: rake -m is required to multithread all tasks.
# However, the current rakefile seems to fail on this
module R::Ake
  DEBUG = true # add some PARANOIA checks, but not a bad idea.
  TRACE = 1 # 0 is none, 2 is full command dumps of the build itself. Works for rake only.
  #TRACE = 0 # 0 is none, 2 is full command dumps of the build itself
  #  TRACE_QT_API = true # or false, output all Qt calls on stderr. Requires rake clean.
  #  works globally and causes heaps of stderr-output!
  TRACE_QT_API = false
  CXX = ENV['CXX'] || ENV['CC'] || 'g++'
  TMPDIR = '.tmp'
  CLEAN.include TMPDIR
  CLOBBER.include LIBRARY
  # mapping dirname=>true, so the paths are auto-unique. Use the keys only
  @linkdirs = { '../reform'=>true }
  # mapping dirname=>true
  @incdirs = {} 
  qt_paths = FileList['/usr/local/Qt5', '/usr/Qt5', '/opt/Qt5']
  ruby_paths = FileList['/usr/local', '/usr', '/opt/ruby']
  ENV['QTDIR'] and qt_paths += [ENV['QTDIR']]
  QT_LINKDIRS = qt_paths.sub(/$/, '/lib')
  QT_INCDIRS = qt_paths.sub(/$/, '/include')
  RUBY_INCDIRS = ruby_paths.map { |path| [ path + '/include/ruby*', path + '/include/ruby*/**' ] }.flatten
  RUBY_LINKDIRS = ruby_paths.sub(/$/, '/lib')

  #STDERR.puts "incdirs = #@incdirs, linkdirs=#@linkdirs"
  MOCSRC = FileList['*.moc.cpp']
  SRC = FileList['*.cpp'] 
  OBJ = (SRC.ext('.o') + MOCSRC.sub(/\.moc\.cpp$/, '.o')).sub(/^/, TMPDIR + '/')
  DEP = SRC.sub(/(.*)\.cpp/, TMPDIR + '/\1.d')

  def self.find_X base, *paths, container, what
    for glob in paths
  #    STDERR.puts "Globbing #{glob}"
      for dir in Dir[glob].reverse
  #      STDERR.puts "Globbing #{dir}/#{base}"
	for path in Dir[dir + '/' + base].reverse
  #	STDERR.puts "test -f #{path}"
	  if File.exists? path
	    container[dir] = true 
	    #STDERR.puts "Located #{base} in #{dir}"
	    return dir
	  end
	end
      end
    end
    raise "#{what.capitalize} #{base} not found in #{paths.join(':')}"
  end

  def self.find_lib lib, *paths
    find_X 'lib' + lib, *paths, @linkdirs, 'library'
  end

  def self.find_inc inc, *paths
    find_X inc, *paths, @incdirs, 'header'
  end

  # returns the resulting text on stdout
  def self.execute cmd, short
    case TRACE
    when 1, true
      $stderr.puts "`#{short}`"
    when 2
      $stderr.puts "`#{cmd}`"
    end
    `#{cmd}`
  end

 # STDERR.puts "locating stuff..."
  find_lib 'Qt5Core.so', *QT_LINKDIRS
  find_lib 'ruby*.so', *RUBY_LINKDIRS
  find_inc 'QtCore/QtCore', *QT_INCDIRS
  find_inc 'ruby.h', *RUBY_INCDIRS
  find_inc 'ruby/config.h', *RUBY_INCDIRS
  find_inc 'ruby/missing.h', *RUBY_INCDIRS

  # This uses the attributes collected above
  # -fPIC is required for Qt
  CXXFLAGS = %w[-Wall -Wextra -Wno-parentheses -fPIC -std=c++11 ] +
	     @incdirs.keys.map { |i| '-I' + i} + 
	     (DEBUG ? %w[-O0 -g -DDEBUG] : %w[-O3]) +
	     (TRACE_QT_API ? ['-DTRACE_QT_API'] : []) +
	     %w[-I.. -I.] +	  # required for local includes
	     INCDIRS.map { |i| '-I' + i}

  # parent directory
  PWD_UP = File.dirname(`pwd`.chomp)
  RPATH = PWD_UP + '/reform'

  LDFLAGS = %w[-fPIC -Wl,-Bsymbolic-functions,-export-dynamic] +
	    ['-Wl,-rpath,' + RPATH] +
	    (DEBUG ? %w[-O0 -g] : %w[-O3]) +
	    @linkdirs.keys.map { |l| '-L' + l} +
	    LINKDIRS.map { |l| '-L' + l} 

  def self.build_it trg
    cmd = [CXX, *CXXFLAGS, '-c', '-x', 'c++', '-o', trg.name, trg.source].shelljoin
    execute cmd, "CXX -> #{trg.name}"
  end

  def self.src2dep src
    File.join(TMPDIR, src.ext('.d'))
  end

  # where unit is a .cpp file
  def self.deps unit
    #STDERR.puts "deps(#{unit})"
    FileUtils.mkdir(TMPDIR) unless File.exists? TMPDIR
    dep = src2dep unit
    depcmd = [CXX, *CXXFLAGS, '-MM', unit].shelljoin
    r = execute(depcmd, 'CPP -> dependencies')
    raise "Creating dep for '#{unit}' failed" if r.strip.empty?
    #STDERR.puts "Now writing to #{dep}"
    File.open(dep, 'w') { |f| f.write r }
    r # !
  end
end # module R::Ake

directory R::Ake::TMPDIR

# NO 'for' please
R::Ake::SRC.each do |unit|
  dep = R::Ake::src2dep unit
  deps = nil
  if File.exists? dep
    File.open(dep) { |f| deps = f.read }
  else
    deps = R::Ake::deps unit
  end
#  STDERR.puts "deps=#{deps}"	OK
  deps = deps.gsub(/^\S+:|\\$/, '').split
  #STDERR.puts "deps=#{deps.inspect}\nSynthing rake file rule"
  file File.join(R::Ake::TMPDIR,unit.ext('.o'))=>deps
  #STDERR.puts "ISSUE file #{dep}=>[#{deps[0]},...]"
  file dep=>deps do |trg|
     R::Ake::deps unit
  end 
end 

rule %r[^\.tmp/.*\.moc$]=>[->tn { tn.sub %r[^\.tmp/(.*)], '\1.h'}] do |trg|
  qtdir = ENV['QTDIR'] and moc = qtdir + '/bin/moc' or moc = 'moc'
  cmd = [moc, trg.source].shelljoin + ' > ' + [trg.name].shelljoin
  R::Ake::execute cmd, "MOC -> #{trg.name}"
end 

# if .cpp changes than .o must be remade
rule(%r[^\.tmp/.*\.o$]=>[->tn{tn.
				 #tap{|t|STDERR.puts "tn=#{t.inspect}"}.
				 sub %r[^\.tmp/(.*)\.o$], '\1.cpp'}]) do |trg|
  R::Ake::build_it trg
end 

rule %r[^\.tmp/.*\.o$]=>[ ->tn {tn.
				  sub(%[^\.tmp/], '').ext('.moc') #.
				  #tap{|t|STDERR.puts "tn=#{t.inspect}"}
			        }] do |trg|
  R::Ake::build_it trg
end 

file LIBRARY=>(R::Ake::DEP + R::Ake::OBJ) do |trg|
  cmd = ([R::Ake::CXX, *R::Ake::LDFLAGS, '-shared', '-o', trg.name, 
	  *R::Ake::OBJ] + LIBS).shelljoin
  R::Ake::execute cmd, "LD -> #{trg.name}"
end

=begin I SAW THIS EXAMPLE:
  Rake::Task[:"mylib.so"].prerequisites.replace(
    [ :"compute_dependencies",
      :"c_file_1.o",
      :"c_file_2.o" ] )

BECAUSE THE CURRENT METHOD ALWAYS calcs the d's.

  both the d files and the o files depend on the contents of the d file.

  And each o and d therefore needs a unique file.
    file X.o=>X.cpp + X.d + `cat X.d`
    file X.d=>X.cpp + `cat X.d`

  And the second file should build the correct reqs for the first.

  Example: rm *.d
  The rules then become:    X.o => X.d =    r
  ret
};

stati
v2sz(
{
#if d
  if 
    r
#endi
  QSi
  Dat
  if 
    r
  ret
};

exter
> X.cpp
  so it regenerates .d and should then alter the X.o reqlist.

  If we change the .cpp file it is regenerated and so is the .o
  If we change X.h later on the dep rules will be OK but X.d
  is remade.
  If we create Y.h and include it in X.cpp then X.cpp is
  remade anyway.
  If we create Z.h and include it in Y.h then Y.h is changed,
  so X.d and X.o are remade.
  If we create A.h and A.cpp then A.o is made anyway.

  It seems foolproof.
=end

desc 'Compiling library'
task buildlib: [R::Ake::TMPDIR, LIBRARY]


