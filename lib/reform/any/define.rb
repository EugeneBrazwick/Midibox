
require_relative '../control'

module R::Qt

=begin
  ANOTHER FINE MESS...

  parameters does NOT process the block.
  So, using:

      parameters {
	name :bla
	....
      }

  will NEVER register :bla.

  And hence any ref to it fails miserably...

  That's probably just why the old code did:

    define {
      bla parameters {.... }
    }

  What about

    w widget { }
    widget :w

  That would be hard, since the first line already makes the widget.

  But maybe:
    define {
      my_canvas canvas { size 100 }	# this must NOT create a canvas
    }
    use :my_canvas, :my_canvas, :my_canvas

  'use' must 'execute' the code that was 'canned'.
  
  This seems just a complicated way of doing:
    3.times { canvas { .. } } 

  And define can be used to 'can' complete forms as well, so to delay the entire setup,
  and even the instantiation.

  This implies saying

    parameters x: X, y: Y ... 

  is identical to 

    setupQuickyhash x: X, y: Y 

  while

    parameters { x X; y Y }

  should be

    instance_eval { x X; y Y }

  CATCH:  parenting.  There is no need for instantiating 'parameters' and storing
      it in the tree. This is even impossible for graphicitems.
  CATCH:  setup should be avoided, use setupQuickyhash and instance_eval. 
      Because setup has overrides that do much more, and the naming is incorrect.
      We should simply add the parameters.

  It is not bad if this works only for parameters, by the way
=end
  class DefineBlock < Control

      class Macro < BasicObject
	private # methdos of Macro
	  def initialize sym, quicky, block
	    @sym, @quicky, @block = sym, quicky, block
	  end # initialize
	  
	public
	  attr :sym, :quicky, :block
      end # class Macro

    public #methods of DefineBlock

      def method_missing sym, *args, &block
	if args.length > 1 
	  super
	elsif args.length == 1 && Macro === args[0]
	  raise ArgumentError, "block given with Macro definition" if block
	  collector!.registerName sym, args[0]
	else
	  quicky = args[0]
	  raise TypeError, "bad quickyhash" unless NilClass === quicky || Hash === quicky
	  Macro.new sym, quicky, block
	end
      end
  end # class DefineBlock

end

Reform.createInstantiator __FILE__, R::Qt::DefineBlock
