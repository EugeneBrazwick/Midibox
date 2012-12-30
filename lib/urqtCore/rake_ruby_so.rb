
require 'rake/clean'
require 'shellwords'

module R
  module Ake; end
end

module R::Ake
  TRACE = 1
  CXX = 'g++'
  CLEAN.include '*.o', '*.d'
  CLOBBER.include LIBRARY
  @linkdirs = {}
  @incdirs = {} 
  qt_paths = %w[ /usr/local/Qt5 /usr/Qt5 /opt/Qt5 ]
  ruby_paths = %w[ /usr/local /usr /opt/ruby ]
  ENV['QTDIR'] and qt_paths += [ENV['QTDIR']]
  QT_LINKDIRS = qt_paths.map { |path| path + '/lib' }
  QT_INCDIRS = qt_paths.map { |path| path + '/include' }
  RUBY_INCDIRS = ruby_paths.map { |path| [ path + '/include/ruby*', path + '/include/ruby*/**' ] }.flatten
  RUBY_LINKDIRS = ruby_paths.map { |path| path + '/lib' }

  #STDERR.puts "incdirs = #@incdirs, linkdirs=#@linkdirs"
  SRC = FileList['*.cpp']
  OBJ = SRC.ext 'o'

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
  CXXFLAGS = %w[-Wall -Wextra -fPIC -Wl,-Bsymbolic-functions -Wl,-export-dynamic ] +
	     (DEBUG ? %w[-O0 -g -DDEBUG] : %w[-O3]) +
	     @linkdirs.keys.map { |l| '-L' + l} +
	     LINKDIRS.map { |l| '-L' + l} +
	     @incdirs.keys.map { |i| '-I' + i} +
	     INCDIRS.map { |i| '-I' + i}

end # module R::Ake
 
for unit in R::Ake::SRC
  cmd = [R::Ake::CXX, *R::Ake::CXXFLAGS, '-MM', unit].shelljoin
  R::Ake::execute(cmd, "CPP -> dependencies");
  deps = `#{cmd}`.gsub(/^\S+:|\\$/, '').split
  #STDERR.puts "deps=#{deps.inspect}\nSynthing rake file rule"
  file unit.ext('.o')=>deps
end 

# if .cpp changes than .o must be remade
rule '.o'=>'.cpp' do |trg|
  cmd = [R::Ake::CXX, *R::Ake::CXXFLAGS, '-c', '-o', trg.name, trg.source].shelljoin
  R::Ake::execute cmd, "CXX -> #{trg.name}"
end 

file LIBRARY=>R::Ake::OBJ do |trg|
  cmd = ([R::Ake::CXX, *R::Ake::CXXFLAGS, '-shared', '-o', trg.name, 
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
  The rules then become:    X.o => X.d => X.cpp
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
task buildlib: LIBRARY


