#!/usr/bin/ruby

# Copyright (c) 2010 Eugene Brazwick
# verified with clean Lucid Ubuntu version on Oct 2 2010.
# Verified with even cleaner Maverick on Oct 27 2010.
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

============================
Maverick: qtbindings is made except for this lib:
-- Skip SMOKE bindings: QtMultimedia
....
cp: cannot stat `ext/build/smoke/qtmultimedia/libsmokeqtmultimedia.*': No such file or directory

Why does it skip it? Is something missing?
Actually, the only thing failing is the 'install' at the end.

Workaround (experimental)
During build remove lines with libsmokeqtmultimedia from the Makefile.
Multimedia stuff will obviously not work.

kdebindings mailing list: https://mail.kde.org/mailman/listinfo/kde-bindings

/usr/include/qt4/QtMultimedia (or something like it) does not exist. Is that the problem?
And it does exist in qt4.6...  See github qtbindings. This is precisely it!

=end

require 'reform/prelims'

if __FILE__ == $0
  prelims = Prelims.new('midibox', Prelims::LinguisticsGem, Prelims::AlsaMidiDriver)
  if ARGV[0] == '--check-reqs'
    ARGV.shift
    # This takes too long for a normal jumpstart. But if you miss some optional stuff
    # it could be usefull.
    prelims.check_reqs
  else
#     STDERR.puts "calling prelims_and_spectest, RUBY=#{ENV['RUBY']}, RUBYLIB=#{ENV['RUBYLIB']}"
    prelims.check_installation
    # It is also tempting to say `exec $RUBY $PWD/gui/mainform.rb &`
    # Otherwise we get a stuck terminal.... So:
    ENV['RUBY'] ||= 'ruby'
    spawn "$RUBY '#{File.dirname(__FILE__)}/../gui/mainform.rb'"
  end
end
