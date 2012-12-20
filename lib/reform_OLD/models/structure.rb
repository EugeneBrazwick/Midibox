
# Copyright (c) 2010-2011 Eugene Brazwick

module Reform

require_relative 'rstore'

=begin
mock:

  struct x: 4, y: [ {x: 34, y: 'world'}, {x: 35, y: 'hallo'}]

  s = { x: 4, y: [ {x: 34, y: 'world'}, {x: 35, y: 'hallo'}] }

  s[:y][0][:y] = 24

  s[:y].map!{|hash| 0}

  => s = {x: 4, y: [0,0]}

  In Qt, changes are coded as index operations. Especially when rows are inserted or removed.

=end

  class Structure < RStore 
     # ?? include ModelContext

    private # methods of Structure

      # [value] the hash, or array, or any object actually
      def initialize value = nil
	super(nil, value)
#	if value
#	  model_pickup_tran(sender) do 
#	    # I think this is the most honoust way of setting up @model_value
#	    value.each { |k, v| self[k] = v } 
#	  end
#	end
      end

    public  # methods of Structure

=begin
      #Note that Hashes will iterate their key as the index. While Array uses the real index.
      # If you use each_with_index on a hash we get el = [key0,value0] and index 0  etc.
      def each_with_index &block
        return to_enum(:each_with_index) unless block
        path = @model_keypath
        if @model_value.respond_to?(:each_pair)
#           tag "#{@model_value.inspect} behaves Hash-like, using each_pair"
          index = 0
          @model_value.each_pair do |key, el|
#             tag "each_pair iteration -> #{index.inspect}, #{el}"
            yield el, index
            index += 1
          end
        elsif @model_value.respond_to?(:each_with_index)
#           tag "#@model_value behaves Array-like"
          @model_value.each_with_index do |el2, index2|
#             tag "YIELD a new Structure on #{el.inspect}, index = #{index}"
            yield el2, index2
          end
        else
          yield self, 0
        end
      end
=end

      # Qt::Base overrides this, so we must overoverride it
      def << value
        self.method_missing(:<<, value)
      end

      # returns the data to send to the external connector if the index changes
      # In case of arrays this is the value, UNLESS the record has a method id.
      # In case of a hash this is the value, only if the values have a method 'id'
      #
      # This is the reverse of model_value2index
      #
      # REASONING: if a hash than probably a hash mapping this key to its instance. But if the instance
      # supports 'id' than passing that instance back and forth seems reasonable.
      # Only if the value has no apparent key do I fallback to the one the hash supplies
      # For example { green: 'yes', red: 'no' }
      # But if is is an array with values it probably OK to use the values as is.
      # But maybe not.
      # In that case use setting key_connector will force passing the key, if it does not exist then the numeric_idx is used as
      # a final solution
      # For hashes, 'key_connector :someid' will tweak the keymethod to use
      def model_index2value numeric_idx, view
        if @model_value.respond_to?(:keys)
          key = @model_value.keys[numeric_idx]
          r = @model_value[key]
#           tag "keys detected, r = #{r}, value2key(#{r}) == #{value2key(r,view)} model_index2value[#{numeric_idx}] -> #{value2key(r,view) ? r : key}"
          model_value2key(r, view) ? r : key
        elsif @model_value.respond_to?(:[])
          return numeric_idx if view.key_connector == :numeric_index
#           tag "arraylike, index2value[#{numeric_idx}] -> #{@model_value[numeric_idx]}"
          r = @model_value[numeric_idx]
          view.key_connector ? model_value2key(r, view) || numeric_idx : r
#           value2key(r, view) ? numeric_idx : r
        else
#           tag "non enumerable value, return #@model_value as is"
          @model_value
        end
      end

      def build &block
        @model_value = {}
#         tag "build, value := {}, + instance eval"
        instance_eval(&block)
        self
      end

      #override
      def model_mimeType
#        tag "#{self}::model_mimeType, getter? #{model_getter?(:model_mimeType)}, value=#{@model_value.inspect}"
        model_getter?(:model_mimeType) ? model_apply_getter(:model_mimeType) : super
      end

      def to_yaml(*args)
        # sooo sneaky...
#         tag "#{@model_value.inspect}::to_yaml"
        @model_value.to_yaml(*args)
      end

      def addModel control, hash, &block
        control.setup hash, &block
#         want_data!            this is a toplevel call. There is no need to do this.
# and it is wrong for comboboxes or lists that are assigned local data.
        @model = control
        control.parent = self
#         added control
      end

  end # class Structure

  createInstantiator File.basename(__FILE__, '.rb'), nil, Structure

end

if __FILE__ == $0
  require 'ostruct'
  t = OpenStruct.new x: 24, y: 'hallo', z: { a: 23, b: 'world', c: { d: 'even deeper' } }
  begin
    puts "t.x = #{t.x}, t.z.b = #{t.z.b}, t.z.c.d = #{t.z.c.d}"
    # you can't say t.z.b, it should be 't.z[:b]'
  rescue
    puts "EXPECTED ERROR: #{$!}"
  end
  class MyStructure < Reform::Structure
    def dynamicPropertyChanged name
      puts "dynamicPropertyChanged: '#{name}'"
      super
    end
  end
  t = MyStructure.new x: 24, y: 'hallo', z: { a: 23, b: 'world', c: { d: 'even deeper' } }
  puts "t.x = #{t.x}, t.z.b = #{t.z.b}, t.z.c.d = #{t.z.c.d}"
  # Still something is wrong, this does NOT send an 'update' message...  FIXED!
  t.z.c.d = 'pindakaas'
  puts "t.x = #{t.x}, t.z.b = #{t.z.b}, t.z.c.d = #{t.z.c.d}"
  t = MyStructure.new x: 24, y: [23, 'hallo', d: {i: :interesting}]
  puts "t.y.class = #{t.y.class}"
  puts "t.y[2].class = #{t.y[2].class}"
  puts "t.y[2].d.i = '#{t.y[2].d.i}'"
  t.y[2].d.i = :not
  puts "t.y[2].d.i is now '#{t.y[2].d.i}', and we were informed!"
end

__END__


Now it's getting interesting...

Structure must be able to wrap around ANY ruby object, making a Model out of it.
This way we can adapt to the Qt::Model interface more easily.

At this point I got the notion of 'keypaths' that denote a path within the model.

If we then use the concept of a root model and we have a way of delivering modelchanges
recursively to those nodes that are interested in changes we don't need observers
anymore.  We just propagate the modelchange to the application and it will send
it to all concerned forms and beyond.

This means that wrapping a ruby object that is not simple, and also not a Hash or
an Array or another Enumerable, should basicly work similar.
We should be able to discover the getters and setters and make them dynamic.

This way there is no longer a need of including Model in an object, you can store
the object in Structure.

An example.

The root object is basicly a bunch of tablelike structures.

  class RootModel
    def styles .... -> array/hash of styles
    def instruments -> ....
    def mood -> ....
    def voices -> ...
    def config -> our global config-tree
    def workspaces -> external data.
  end

root = RootModel.new(somepath)

We can now open a form that displays root.styles. The keypath of this form is then [:styles]
If you then open a form to display style 'Euro Dance' the keypath can be [:styles, 123]

So at a certain point a transaction is committed on the model. This will send the
RootModel in its entirety to the application.
Let's say that workspaces['test.mbox'] has been altered. That would be the keypath
[:workspaces, 'file://test.mbox'] something like that.
An 'initialization' message would visit all forms, but if the altered keypath would be
[:workspaces ,... ] then all forms except those with a similar prefix in their keypath
would listen.


Now a single transaction may change more than one keypath, and may also cause deletions
and or inserts.

So assuming a form has a connector + keypath to the rootmodel it will apply the standard
propagation rules.
The connector is applied to the keypaths first.
All keypaths starting with that connector will remain, but the first element pops.
If nothing remains than we are not interested in the event (unless 'init' it set)
Next we apply the connector to the rootmodel.

A connector is simply a part of the keypath.

Four complications:
  - changes that cause other attributes to change instead of a single one.
  - the ability to use blocks as getters and setters
  - expensive parts in the keypath
  - changes that insert or delete array entries and so totally mess up and controls
    whose keypath has an array index in them. Like [:styles, 123].
    So we need specific messages for those events so they can cope.

class Root
  attr :x

  def y
    x
  end
end

This model has two getters, 'x' and 'y'.  If a control has a connector 'y' then we must make
sure that changes to 'x' also insert the 'y' keypath as being altered.
This is a very common case.  Take the time-model for instance. If the 'current' time changes
all dependent attributes like 'angle' and 'hours' etc.. must be marked as changed as well!
This can not be solved in our wrapper but must be dealt with in the Model module instead.
But it might be possible to add hints to the wrapper in the form of specifically named methods.
For example:
    def reform_dependencies
      { :current => [:to_s, :to_str, :angle, ... ], :b => :a ..... }
    end

Procs as [GS]etters
====================

  edit {
    connector { |m| m.a.to_s }
    setter { |m, value| m.a = value.to_i }
    connector :a, -> a { a.to_s }
  }

Since the 'setter' changes 'a' that is easy enough.
A connector without procs can be used as a setter.
But the setter can also be a keypath or immediate key.
If the thing connecting is an array the connector can be an integer.

A connector that is a proc will always reconnect if the propertychange propagates to it.
If it also has a keypath we will check up to the proc.
So if [:a, ->a{a.to_s}] then we will reconnect if :a has changed in the passed model.

Arrays as [GS]etters
====================
Work as if each element is applied on the result of applying the previous one.
So [:f, :g]  applied on x would be x.f.g.

Expensive Parts
================

Persistance
============
Assuming that the application is stable enough, a timed save of the rootdata will work
as a persistance trick (or when exiting). We can save 'backups' every 10 minutes or so.
The computer can save let's say > 100MB per second (on SSD's for example) so for simplistic
apps this should in fact be more than sufficient.

External components
===================

By representing external components as pools indexed by filename we can even incorporate
fileopen/save dialogs properly.

Complicated alterations
=======================

   m = Structure.new([1,2,3,4])
   m[2, 3] = 88, 89, 90
   now m = [1, 2, 88, 89, 90]

We will simply take these as 'replacing' the array as a whole. These kind of operations are rare.
Could be when we drag a selection over into a list or so. Just updating the entire contents would be
OK.

NOT OK at all. Especially when array operations are involved, we can assume these arrays can be
quite big.  The change must be done as efficient as possible.  This is even more true if controls
are watching 'm' or any subpart of it.  Replacing the array will not work correctly. The control
that has m[4] open for example, must change to m[5] if we do m[0,2] = a,b,c!! And it does not need
to reload or update the screen, since we know the change is purely internal.

Identity
=============

The identity of parts of the model cannot be guaranteed. Sometimes aborting a transaction
will replace a part of the model with a clone.

  c = [34, 23, 3543]
  m = { s: 12,  d: c}
  m.transaction do |tran|
    m.d.map!{|x| x+1}
    ..
    tran.abort
  end

Now d will be [34, 23, 3543] again but is no longer equal to c!
Even more c will be equal to [35, 24, 3544]

These are features....
