
require_relative '../../lib/rpp/rpp'
require 'dl'

describe "RPP::Module" do
  before :all do
    @librpprpp = DL.dlopen File.dirname(__FILE__) + '/../../lib/rpp/librpprpp.so'
  end

  it "should create a ruby module" do
    RPP::Module.new 'Bastard'
    Bastard.class.should == Module
  end

  it "should be able to wrap a C function, to create a method" do
    bas = RPP::Module.new 'Bastard'
    bas.classname.should == 'Module' # this is cRPP_BasicObject_classname in action
    klass = RPP::Class.new 'Classy'
    # complicated but using cRPP_BasicObject_classname fails utterly.
    # But that is to be expected since it is a method of cRPP_BasicObject iso RPP::cBasicObject.
    # But in ruby RPP::BasicObject is cRPP_BasicObject. 
    klass.define_method 'klassname', @librpprpp['RPP_cBasicObject_classname']
    # and now call it:
    classy = Classy.new
    classy.klassname.should == 'Classy'
  end

=begin

  FATAL FLAWS:
      1 - the cpp code will use patternmatching to guarantee type-safety.
	  we cannot do that and must revert to rb_define_method() RAW.
	  That is, we need a third arg to denote how many arguments there are (or -1).
	  Workaround. See 'clang mangle itanium ABI' (GNU 3.2 and higher)
	  Or the source of c++-filt.
	  We can use the mangled C++ name and somehow tell the RPP::Class where to load the so.
	  So that define_method can be passed the mangled name, and it can load the functionptr
	  in the C-code.
	  Example:
	    klass.define_method('klassname', 'x.so', '_ZN3RPP10DataObjectINS_5ClassEEE').

      2 - classes and modules can easily be defined in bits of ruby combined with cpp.
          Using the .so only will omit certain key methods for sure.
	  And that is the killer bit. 
	  However, this is a toy, only created to facilitate spec testing the ruby++ lib.
	  So we can decide to fully build the wrapper in cpp.
	  Finally, define_method is 'just' rb_define_method. 
	  So, for example, we can setup a class X:
	      
	      class X
		def f ..... 
		end
	      end
	      rpp_x = RPP::Class.new 'X'
	      rpp_x.define_method 'g', 'g.so', '_ZN3RPP10DataObjectINS_5ClassEEE'
	      x = X.new
	      x.f
	      x.g

	  Interesting enough, the only format a C++ method can have would be:
		VALUE (*)(VALUE)
		VALUE (*)(VALUE, VALUE)
		VALUE (*)(VALUE, VALUE, VALUE)
		VALUE (*)(VALUE, VALUE, VALUE, VALUE)
		VALUE (*)(VALUE, VALUE, VALUE, VALUE, VALUE)
		VALUE (*)(int, VALUE *, VALUE)
	  Only 6 possibilities.
	  So our demangle system should be extremely predictable and can be very simple.


=end
end
