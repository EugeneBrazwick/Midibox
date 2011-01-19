
# Copyright (c) 2011 Eugene Brazwick

# Verified with clean Maverick: NOT
# Verified with clean Fedora: NOT

require 'reform/prelims'

if __FILE__ == $0
  prelims = Prelims.new('reform')
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
    spawn ENV['RUBY'], *ARGV
  end
end
