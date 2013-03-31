
# I decided to port QObject more or less complete.
# Since it should all work and most features are pretty handy!

require_relative '../../lib/reform/core_app'
#  require 'timeout' BROKEN with Qt

include R
describe "Qt::Object" do
  it "should create new instances without objectName, parent or children" do
    o = Qt::Object.new
    o.objectName.should == nil	# nil is much more convenient than ''
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

  # anti-pattern that cannot be tested easily: if ruby object is cleaned up from memory
  # the QObject remains! Note however that QObject parents will delete all their
  # children if deleted themselves. It would in fact be inconvenient of Qt::Object would
  # autodelete.
 
  it "should become a zombie when going out of scope" do
    # the reverse. The C++ object is deleted.  Ruby wrapper survives but becomes a 'zombie'
    # (since it should be dead...).
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
    froome = Qt::Object.new { objectName 'froome' }
    # it is just an initializer and leaves the object alive afterwards.
    froome.should_not be_zombified
    froome.delete
    Qt::Object.new { objectName 'froome' }.scope do |froome|
      froome.objectName.should == 'froome'
    end
  end

  it "you can set a parent and that parent kills the child with it, when deleted" do
    fifi = nil
    Qt::Object.new { objectName 'froome' }.scope do |froome|
      fifi = Qt::Object.new froome, 'fifi'
      fifi.objectName.should == 'fifi'
      fifi.parent.should == froome
    end
    fifi.should be_zombified
  end
  
  it "makes a named child available as a method under its parent" do
    Qt::Object.new('froome').scope do |froome|
      fifi = Qt::Object.new(froome, 'fifi')
      fifi.should == froome.fifi
    end
  end

  it "checks the type for the parent correctly" do
    Qt::Object.new { objectName 'froome' }.scope do |froome|
      expect { froome.qtparent = 'bart' }.to raise_error TypeError
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
      froome.qtchildren = fifi
      fifi.parent.should == froome
      frodo.children.should be_empty
      frodo.parent.should == nil
      frodo.delete # ... ensure???
    end
  end

  it "will remove deleted children automatically from the parent" do
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

  it "supports ruby signals and slots" do

    Counter.new(3).scope do |counter|
      counter2 = Counter.new { parent counter }
      counter.valueChanged { |v| counter2.value = v }
      counter.instance_variable_get("@r_qt_connections").length.should == 1
      # a disadvantage is that you cannot pass a block as a single argument to a
      # signal. In that case, use a lambda...
      # counter.valueChanged -> v { puts 'weird idea' }
      # Anyway, you should not use the signal like that.
      counter2.value.should == 0
      counter.value = 4
      counter2.value.should == 4
    end # scope
  end 

  it "a ruby signal can only have a single handler" do
    Counter.new(3).scope do |counter|
      counter2 = Counter.new { parent counter }
      counter.valueChanged { |v| counter2.value = 2 * v }
      # this overwrites the earlier 'valueChanged':
      counter.valueChanged { |v| counter2.value = v }
      counter.instance_variable_get("@r_qt_connections").length.should == 1
    end
  end

  it "is possible to drop the signalhandler" do
    Counter.new(3).scope do |counter|
      counter2 = Counter.new { parent counter }
      counter.valueChanged { |v| counter2.value = v }
      counter.disconnect :valueChanged
      counter.instance_variable_get("@r_qt_connections").length.should == 0
      counter2.value.should == 0
      counter.value = 4
      counter2.value.should == 0
    end
  end

  it "supports native Qt signals, but not slots" do
    $glob = 14
    Qt::Object.new('fifi').scope do |fifi|
      fifi.destroyed { |who| who.should == fifi; $glob = 2 }
    end # scope
    $glob.should == 2
  end # it

  it "can enumerate all immediate ruby children" do
    Qt::Object.new(objectName: 'fifi').scope do |fifi|
      frodo, linda = Qt::Object.new('frodo'), Qt::Object.new('linda')
      fifi.qtchildren = frodo, linda
      fifi.each.to_a.should == [frodo, linda]
    end
  end # it

  class Dog < Qt::Object
  end

  def o name; Qt::Object.new name; end
  def d name; Dog.new name; end

  it "can enumerate all subs breadth-first" do
    Qt::Object.new(objectName: 'fifi').scope do |fifi|
      frodo, linda = o('frodo'), o('linda')
      carl, philip, emmanuel = %w[carl philip emmanuel].map{|b| o b}
      johan = o 'johan'
      fifi.qtchildren = frodo, linda
      frodo.qtchildren = carl, philip, emmanuel
      linda.qtchildren = johan
      fifi.each_sub.to_a.should == [frodo, linda, carl, philip, emmanuel, johan]
      fifi.each_sub_with_root.to_a.should == [fifi, frodo, linda, carl, philip, emmanuel, johan]
      fifi.each_child.to_a.should == [frodo, linda]
      fifi.each_child_with_root.to_a.should == [fifi, frodo, linda]
    end
  end # it

  it "can use 'findChild' to make queries" do
    d('fifi').scope do |fifi|
      frodo, linda = d('frodo'), o('linda')
      carl, philip, emmanuel = %w[carl philip emmanuel].map{|b| o b}
      johan = d 'johan'
      fifi.qtchildren = frodo, linda
      frodo.qtchildren = carl, philip, emmanuel
      linda.qtchildren = johan
      # on objectName:
      fifi.findChild('frodo').should == frodo
      fifi.findChild('frodo', Qt::Object).should == frodo
      # on Class as well:
      fifi.findChild(Dog, 'johan').should == johan
      fifi.findChild(Dog, 'linda').should == nil
      fifi.findChild.should == frodo
      # special flags:
      fifi.findChild(include_root: true).should == fifi
      fifi.findChild(Dog, include_root: true).should == fifi
      linda.findChild(Dog, include_root: true).should == johan
      fifi.findChild(Dog, recursive: false).should == frodo
      fifi.findChild(Dog, 'johan', recursive: false).should == nil
      # and accepts a block, like 'find':
      fifi.findChild(recursive: false){|el| Dog === el}.should == frodo
      fifi.findChild {|el| el.objectName[0] == 'l'}.should == linda
    end
  end # it
  
  it "zombies should survive GC" do
    Qt::Object.new.scope do |parent|   
      tricky = child = Qt::Object.new(parent)
      child.delete
      tricky.should be_zombified
      child.should be_zombified
      child = nil
      #tag "GC"
      ObjectSpace.garbage_collect
      # this will GC child, but that should not leave tricky DEAD.
      #tag "tricky test"
      tricky.should be_zombified
      # OK, he's only a zombie
    end
  end #it

  it "should not zombify tricky children" do
    # is it possible to leave a DEAD ruby instance in a live Qt instance?
    herman = nil
    Qt::Object.new('leo').scope do |leo| 
      ch = Qt::Object.new leo, 'herman'
      ch = nil
      ObjectSpace.garbage_collect
      herman = leo.findChild 'herman'
      herman.objectName.should == 'herman'
      herman.qtparent = nil
      # leo is deleted here, but herman survives
    end
    herman.objectName.should == 'herman'
    herman.should_not be_zombified
  end #it

  it "should not try to confuse the programmer with tricky children" do
    # is it possible to leave a DEAD ruby instance in a live Qt instance?
    herman = nil
    Qt::Object.new('leo').scope do |leo| 
      ch = Qt::Object.new leo, 'herman'
      ch = nil
      ObjectSpace.garbage_collect
      herman = leo.findChild 'herman'
      herman.objectName.should == 'herman'
      # leo is deleted here, and herman too
    end
    herman.should be_zombified
  end #it

  it "can catch child events" do
    $received_childAdded = false
    $received_childRemoved = false
    # SEGV alert Timeout::timeout 2 do
      #     Reform.core_app { # unfortunately this breaks rspec.... 
      Qt::CoreApplication.new.scope do |app| 
	Qt::Object.new('herman').scope do |herman|
	  herman.childAdded { |child| child.objectName.should == 'leo'; $received_childAdded = true }
	  herman.childRemoved { |child| child.should be_zombified; $received_childRemoved = true }
	  $received_childAdded.should == false
	  leo = Qt::Object.new 'leo', herman
	  leo.delete 
	  app.quit
	end
	# app.exec will start a loop and we cannot enter it very easily.
	# Also Qt does it well. Even if quit is called we still handle all events posted.
	# I'm pretty sure this tricks fails in gui Application.
	app.exec
      end 
    #end
    $received_childAdded.should == true
    $received_childRemoved.should == true
  end

  it "can catch timer events" do
    $got_event = false
    #Timeout::timeout 2 do    CAUSES SEGV and does NOT interrupt the following loop either
    # and I used startTimer 5_000 
      Qt::CoreApplication.new.scope do |app| 
	id = app.startTimer 100
	app.timerEvent do |idt|
	  idt.should == id
	  app.quit
	  app.killTimer idt
	  $got_event = true
	end
	app.exec
      end 
    #end
    $got_event.should == true
  end

  it "can catch dynamic property events" do
    $got_event = false
    # SEGV    Timeout::timeout 2 do
      Qt::CoreApplication.new.scope do |app| 
	app.dynamicPropertyChanged do |propname|
	  propname.should == 'neat'
	  $got_event = true
	  app.quit
	end
	app.setProperty 'neat', 120
	app.exec
      end 
    #end
    $got_event.should == true
  end
end # describe
