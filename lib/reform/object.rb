
require_relative '../urqtCore/liburqtCore' 

module Kernel
  private # methods of Kernel
    def tag msg
      # avoid puts for threading problems
      STDERR.print "#{File.basename(caller[0])} #{msg}\n"
    end # msg

end # module Kernel

module R::Qt

  ## 
  # This class supports constructing and setting up simple objects
  #
  # However:
  #	- slots/signals not supported 
  #	- no access to properties
  #	- events not supported
  #	- metaobject system not supported
  # 
  # Because I believe ruby can do all these things already.
  #
    class Object
      private # methods of Object
	# Note that using a hash or a block should not matter ONE YOTA
	# that's why we call the getters here, and expect them to be setters!
	def setupQuickyhash hash
	  #tag "setupQuickyhash(#{hash})"
	  for k, v in hash
	    case v
	    when Array
	      send k, *v
	    else
	      send k, v
	    end
	  end # for
	end # setupQuickyhash

	def self.create_qt_signal s
	  '2' + s
	end

      public # methods of Object

	# guarantees free of the C++ instance.
	def scope 
	  yield self
	ensure
	  delete
	end # scope

	# always recursive unless opts[:recursive] is false
	# if name is not a string and a block is passed 
	# we bypass the Qt system but use the same semantics
        def findChild name = nil, opts = nil 
	end

	def self.signal *signals
	  for method in signals
	    m = method.to_s.sub(/\(.*/, '')
	    define_method m do |*args, &block|
	      #tag "signal method #{m} called"
	      if block && args.empty?
		#tag "connecting signal to block"
		connect method, block
	      else
		tag "emitting signal with args #{args}"
		# IMPORTANT object.cpp has no support for blocks
		emit method, *args, &block 
	      end
	    end
	  end
	end # signal

	signal 'destroyed(QObject *)'
    end  #class Object

  public # methods of R::Qt

end # module R::Qt

# I decided to port QObject more or less complete.
# Since it should all work and most features are pretty handy!

if File.basename($0) == 'rspec'
  include R
  describe "Qt::Object" do
    it "should create new instances without objectName, parent or children" do
      o = Qt::Object.new
      o.objectName.should == ''
      o.parent.should == nil
      o.children.should be_empty
      o.delete
    end

    it "should get and set objectName" do
      o = Qt::Object.new
      o.objectName = 'hallo'
      o.objectName.should == 'hallo'
      o.delete
    end

    it "should set with a get too" do
      o = Qt::Object.new
      o.objectName 'Blurb'
      o.objectName.should == 'Blurb'
      o.delete
    end

    it "should become a zombie with delete" do
      o = Qt::Object.new
      o.delete
      o.should be_zombified
    end

    it "should become a zombie when going out of scope" do
      p = nil
      Qt::Object.new.scope { |o| p = o }
      p.should be_zombified
    end

    it "we can pass a name, or a parent or a parameterhash in any order " +
       "and they execute in sequence" do
      Qt::Object.new('fifi', objectName: 'frodo') do |frodo|
	frodo.objectName.should == 'frodo'
      end
    end

    it "you can pass a block and it is executed in the context of the object" do
      Qt::Object.new { objectName 'froome' }.scope do |froome|
	froome.objectName.should == 'froome'
      end
    end

    it "you can set a parent and it kills the child with it" do
      fifi = nil
      Qt::Object.new { objectName 'froome' }.scope do |froome|
	fifi = Qt::Object.new(froome, 'fifi')
	fifi.objectName.should == 'fifi'
	fifi.parent.should == froome
      end
      fifi.should be_zombified
    end

    it "checks the type for the parent correctly" do
      Qt::Object.new { objectName 'froome' }.scope do |froome|
	expect { froome.parent = 'bart' }.to raise_error TypeError
      end
    end

    it "does not like zombies for parents too" do
      fifi = Qt::Object.new
      fifi.delete
      expect { Qt::Object.new fifi }.to raise_error TypeError
    end

    it "can be parented using a hash too" do
      fifi = nil
      Qt::Object.new(objectName: 'froome').scope do |froome|
	fifi = Qt::Object.new parent: froome, objectName: 'fifi'
	fifi.objectName.should == 'fifi'
	fifi.parent.should == froome
      end
      fifi.should be_zombified
    end

    it "we can replace all children, but a child can only have one parent" do
      Qt::Object.new(objectName: 'froome').scope do |froome|
	frodo = Qt::Object.new froome, 'frodo'
	fifi = Qt::Object.new 'fifi', frodo
	fifi.parent.should == frodo
	frodo.children.should == [fifi]
	froome.children fifi
	fifi.parent.should == froome
	frodo.children.should be_empty
	frodo.parent.should == nil
	frodo.delete # ... ensure???
      end
    end

    it "will delete zombified children" do
      Qt::Object.new(objectName: 'froome').scope do |froome|
	frodo = Qt::Object.new froome, 'frodo'
	froome.children.should == [frodo]
	frodo.delete
	froome.children.should be_empty
      end
    end

    it "is OK to delete a zombie" do
      frodo = Qt::Object.new
      frodo.delete
      frodo.delete
      frodo.delete
    end

    it "is BAD to try Qt stuff on zombies" do
      frodo = Qt::Object.new
      frodo.delete
      expect { frodo.objectName = 'pete' }.to raise_error TypeError
    end

    it "supports ruby signals and slots" do

      # the signal and slot system, the code I wished I had:
      class Counter < Qt::Object
	  def initialize value = 0
	    super()
	    @value = value 
	  end

	  attr_reader :value

	  def value= v
	    valueChanged @value = v
	  end

	  signal :valueChanged
      end

      Counter.new(3).scope do |counter|
	counter2 = Counter.new { parent counter }
	counter.valueChanged { |v| counter2.value = v }
	counter.instance_variable_get("@connections").length.should == 1
	# a disadvantage is that you cannot pass a block as a single argument to a
	# signal. In that case, use a lambda...
	# counter.valueChanged -> v { puts 'weird idea' }
	# Anyway, you should not use the signal like that.
	counter2.value.should == 0
	counter.value = 4
	counter2.value.should == 4
      end # scope
    end 

    # it "supports blockSignals on ruby signals"

    it "supports native Qt signals, but not slots" do
      $glob = 14
      Qt::Object.new(objectName: 'fifi').scope do |fifi|
	fifi.destroyed { |who| who.should == fifi; $glob = 2 }
      end # scope
      $glob.should == 2
    end # it

    it "can enumerate all immediate ruby children" do
      Qt::Object.new(objectName: 'fifi').scope do |fifi|
	frodo, linda = Qt::Object.new('frodo'), Qt::Object.new('linda')
	fifi.children frodo, linda
	fifi.each.to_a.should == [frodo, linda]
      end
    end # it

    it "can enumerate all subs breadth-first" do
      def o name; Qt::Object.new name; end

      Qt::Object.new(objectName: 'fifi').scope do |fifi|
	frodo, linda = o('frodo'), o('linda')
	carl, philip, emmanuel = %w[carl philip emmanuel].map{|b| o b}
	johan = o 'johan'
	fifi.children frodo, linda
	frodo.children carl, philip, emmanuel
	linda.children johan
	fifi.each_sub.to_a.should == [frodo, linda, carl, philip, emmanuel, johan]
      end
    end # it
  end # describe
end # if
