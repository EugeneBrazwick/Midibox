#!/usr/bin/ruby -w
#encoding: utf-8

require 'Qt'

class C < Qt::Object

  def helloworld text
    puts "RECEIVED text.encoding = #{text.encoding}"
    puts "text = #{text}, bytes=#{text.bytes.to_a.inspect}"
  end

  signals 'hola(const QString&)'
  slots 'helloworld(const QString&)'

  def initialize
    super
    connect(self, SIGNAL('hola(const QString&)'), self, SLOT('helloworld(const QString&)'))
  end

  def test_it
    text = ''
    puts "SENDING text.encoding = #{text.encoding}"
    puts "text = #{text}, bytes=#{text.bytes.to_a.inspect}"
    emit hola(text)  # this is a 'phone' symbol, aka U0007
          # since historically 0x7 is used as a 'bell'...
  end
end

c = C.new
c.test_it

