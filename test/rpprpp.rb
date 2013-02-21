require 'dl'

=begin	not going to work.
module BO
  extend DL::Importer
  dlload '~/Midibox/lib/rpp/librpprpp.so'
  # this only works if VALUE is actually unsigned long. (so not on Windows 64 bit, since it is 32 bit)
  extern 'unsigned long cRPP_BasicObject_classname(unsigned long)'
  alias classname cRPP_BasicObject_classname
end
=end

require_relative '../lib/rpp/rpp.rb'

mod = RPP::Module.new 'Bastard'

lib = DL.dlopen "#{ENV['HOME']}/Midibox/lib/rpp/librpprpp.so"
puts "cRPP_BasicObject_classname -> #{lib['cRPP_BasicObject_classname'].inspect}"
puts "lib -> #{lib.class}, lib[] -> #{lib['cRPP_BasicObject_classname'].class}"
  # result a Fixnum...
# puts "nil.classname? = #{BO.cRPP_BasicObject_classname(mod.__id__)}"
