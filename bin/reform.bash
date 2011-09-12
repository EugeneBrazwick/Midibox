#!/bin/bash
# Copyright (c) 2011 Eugene Brazwick
# verified: no
rundir=$(dirname $0)
# echo rundir=$rundir
[ "$PREFIX" ] || export PREFIX=/usr
while [ -z "$RUBY" ]; do
  [ -f ~/.rvm/scripts/rvm ] && source ~/.rvm/scripts/rvm
  export RUBY=$(which ruby)
  [ "$RUBY" ] || export RUBY=$(ls "$PREFIX"/bin/ruby* | tail --lines=1)
  if [ -z "$RUBY" ]; then
    echo 'ruby is not installed. If it is, please set $RUBY before starting this script.'
    echo "try to install it now (requires apt-get compat system)?"
    echo -n "[Yn] "
    read answer
    case "$answer" in
    ([Yy]*|'')
      if [ "$(which apt-get)" ]; then
        if [ ! "$(which aptitude)" ]; then
          sudo apt-get --yes install aptitude
          if [ ! "$(which aptitude)" ]; then
            echo "Could not install aptitude"
            exit 3
          fi
        fi
        export RUBY="$PREFIX"/bin/$(aptitude search --display-format '%p' '^ruby[0-9\.]+$' | \
                                    sort --general-numeric-sort | tail --lines 1 | sed 's/ *$//')
        [ "$RUBY" ] || { echo "could not locate latest ruby version for apt"; exit 3; }
        package=$(aptitude search --display-format '%p' '^'"$RUBY"'-full$' | sed 's/ *$//')
        [ "$package" ] || package=$RUBY
        echo sudo apt-get --yes install "$package"
        sudo apt-get --yes install "$package"
        if [ "$RUBY" == "$PREFIX"/bin/ruby1.9.2 -a ! "$(which $RUBY)" -a "$(which "$PREFIX"/bin/ruby1.9.1)" ]; then
          RUBY="$PREFIX"/bin/ruby.1.9.1
        fi
      elif [ "$(which yum)" ]; then
        echo "su -c 'yum --assumeyes install rubygem-rvm'"
        su -c 'yum --assumeyes install rubygem-rvm gcc-c++ patch readline readline-devel zlib
               zlib-devel libyaml-devel libffi-devel'
        rvm-install --help > /dev/null 2>&1
        source "$HOME/.rvm/scripts/bin/rvm"
        RUBY_PACK=ruby-1.9.2-p0
        rvm install $RUBY_PACK
        rvm $RUBY_PACK --default
        RUBY=$(which ruby)  # something like ~/.rvm/rubies/ruby-1.9.2-p0/bin/ruby
      else
        echo "Unfortunately, you will have to install it yourself"
        exit 2
      fi
      ;;
    (*) exit 1;;
    esac
  fi
done
case "$RUBYLIB" in
($rundir) ;;
('') export RUBYLIB="$rundir/../lib";;
(*) export RUBYLIB="$rundir/../lib:$RUBYLIB";;
esac
export RUBY
exec "$RUBY" "$rundir/reform_launcher.rb" "$@"
