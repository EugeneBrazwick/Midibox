#!/usr/bin/ruby
require 'rubygems'
require 'test/unit'
require 'shoulda'
require_relative '../lib/reform/app'

class ReformAppTest < Test::Unit::TestCase
  context 'app' do
    setup do
      require_relative '../lib/reform/app'
    end

=begin

It does not work like this. 'app' starts the eventloop and that will
just display a form. Basicly you CANNOT create two.
    should "behave like a singleton" do
      Reform::app
#       assert_raise SomeError { Reform::app }
    end
=end

  end # context 'app'
end