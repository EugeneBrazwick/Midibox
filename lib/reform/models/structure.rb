

class Array
  def has_key? i
    Fixnum === i && (i >= 0 && i < length) || (i < 0 && -i <= length)
  end
end

module Reform

require 'reform/model'

=begin

Slightly simplistic and incomplete wrapper for anything simple, up to
arrays and hashes.

Hashes have read and write support for the [] and []= only!!!
Arrays were added later and support all writeops but for reading
only [] once again.

All unsupported methods will work but writes will not be noticed
by the model, and reads may return raw Array and Hash instances.

For simplistic JSON like operations it functions excelently, and missing
stuff can easily be implemented as the 'ArrayWrapper' shows.

=============================================
Must be changed to support transactions.
Or better said: "undo's"

====
Must be changed to support submodels.

The thing that changes is not simply a fieldname.

mock:

  simplestruct x: 4, y: [ {x: 34, y: 'world'}, {x: 35, y: 'hallo'}]

  s = { x: 4, y: [ {x: 34, y: 'world'}, {x: 35, y: 'hallo'}] }

  s[:y][0][:y] = 24

  s[:y].map!{|hash| 0}

  => s = {x: 4, y: [0,0]}

  In Qt, changes are coded as index operations. Especially when rows are inserted or removed.

  Basicly we should follow the Qt method and use Index instances.  But now they can also
  be hash keys (so anything).

  A change=index can be an array of fields, like [:y, 0, :y]

  So an undo operation contains the changed index, the operation-kind (like insert/delete/replace) and the old value.

      s = SimpleStruct.new x: 4, y: [ {x: 34, y: 'world'}, {x: 35, y: 'hallo'}]

      s.transaction(self) do |tran|
        s[:y][0][:y] = 24
        tran.abort
      end
      s.transaction(self) do |tran|
        s[:y][0][:y] = 24
        s[:y].map!{|hash| 0}
        tran.abort
      end

      Both examples are property changes, the first has model s, index [:y,0,:y] and prevval s[:y][0][:y]
      the second has model s, index[:y] and prevval s[:y].clone
      It is obviously incorrect of storing s[:y] itself since it is going to be mutilated by map!

  But as discussed earlier, this makes aborting the transaction change the data.
  So basicly we must decide here that changing items in place is invalid and must be rerouted to do this:

        Transaction::transaction.addPropertyChange :y, s[:y]
        s[:y] = s[:y].map{|hash| 0}

  This is only less efficient. The end result is the same.
  No! BS.
    Example:
        z = s[:y]
        s[:y].map!{...}
    This changes z too. So if we clone s[:y] for the abort then aborting will result in z no longer identical to s[:y] .
    And if I reassign s[:y] then the commit wil break the bond.

    So such operations require a commit that actually changes the result.

      z = s[:y]
      s.transaction(self) do |tran|
        s[:y].map!{...}   ->    I)    store original s[:y] for abort
                                II)   assign map to s[:y]
      end        III) == commit == reassign s[:y] and execute map!{...}

    This is clumsy and will never work correctly.
    Because of this we can ignore external and internal references.
    For map! we make a clone to restore, and for map it can be the previous reference.

    s = [1,4,9, 16]             s[2,2] = [9,16]
    s[2,2] = nil                propagate [[2,2]]
    -> s = [1, 4, nil]

    s = [1,4,9,16]
    s[2,2] = []
    -> s = [1, 4]
    s[2, 2] = [9,16]
    -> s = [1,4,9,16]

    this is slightly ambiguous.

    s[3] = x is the same as s[3,1] = x or s[3,1] = [x]
    s[3]=x,y is the same as s[3,0] =x,y or s[3,0] = [x,y]
    It differs whether the righthand side is an array or not. And s[0] = [3,2] is different from s[0,0] = [3,2] !
=end
  class Structure
    include Model

=begin
      class ArrayWrapper
        private
#           def self.def_single_delegators(accessor, *methods)
#             methods.delete("__send__")
#             methods.delete("__id__")
#             for method in methods
#               def_single_delegator(accessor, method)
#             end
#           end

          # this is complicated. We must add to the Transaction, implying that we
          # must be able to undo it.
          def self.def_single_delegator(accessor, method, ali = method)
            line_no = __LINE__; str = %<
              def #{ali}(*args, &block)
                raise 'NOTIMPLEMENTED'
                begin
                  tag "DELEGATION, method = '#{method}'"
                  #{accessor}.__send__(:#{method}, *args, &block)
                  @root.dynamicPropertyChanged @propname
                rescue Exception
                  # hack the backtrace to not include "structure.rb" references
                  $@.delete_if{|s| %r"#{Regexp.quote(__FILE__)}"o =~ s} unless Forwardable::debug
                  ::Kernel::raise
                end
              end
            >
            instance_eval(str, __FILE__, line_no)
          end

        public


          # next thing: all stuff returning array elements must wrap them, if they are a plain hash or
          # an array themselves...
          def [] idx
            @@root.wrap(@ar.send(:[], idx), idx, @keypath)
          end

          def method_missing sym, *args, &block
            @ar.send(sym, *args, &block)
          end
      end # class ArrayWrapper
=end

    private # methods of Structure

      # Named parameters, in case arg1 is a hash
      # [parent] owner control, or a wrapped value.
      # [root] the root
      # [value] the value
      # [qtc] Qt implementor (if parent is a control) or the root-structure otherwise
      # [keypath] array of indices that lead to this value within the root-structure.
      #           nil (default) is equivalent with [].
      #           Only applies when a root is given
      def initialize *args
#         tag "INITIALIZE ,args = #{args.inspect}"
        if args.length == 1
          args = args[0]
          if Hash === args && args[:keypath]
  #         tag "#{self}.new(#{parent.inspect}, gp=#{qtc}"
            @value = args[:value]
            raise 'TRYING TO MAKE A MESS????' if @value.nil?
            @root = args[:root]
            @keypath = args[:keypath]
            return
          end
        end
        @root = self
#         tag "setup @value := #{args}"
        @value = args
        raise 'TRYING TO MAKE A MESS????' if @value.nil?
        @keypath = nil
#         tag "INIT OK"
      end

      def assign key, value, org_symbol = nil
#         tag "Assign #{key.inspect}, #{value}, currentvalue=#{@value.inspect}, keypath=#{@keypath.inspect}"
        case key
        when :self
#           tag "#{self} ASSIGN self @value := #{value}"
          @value = value
          raise 'TRYING TO MAKE A MESS????' if @value.nil?
        when Array
          @value[*key] = value
        else
          org_symbol ||= (key.to_s + '=').to_sym      # the caller sometimes knows this, so we could pass it as option
#           tag "does #@value (class #{@value.class}) respond_to #{org_symbol.inspect}"
          if org_symbol != :[]= && @value.respond_to?(org_symbol)
#             tag "YES, send it"
            @value.send(org_symbol, value)
          else
#             tag "NO, apply index @value[#{key}] := #{value}"
            @value[key] = value
          end
        end
      end

      def calc_prev name
#         tag "calc_prev(#{name.inspect})"
        case name
        when :self
          @value
        when Symbol
          if @value.respond_to?(name)
#             tag "true getter"
            @value.send(name)
          else
            name2 = (name.to_s + '?').to_sym
            if @value.respond_to?(name2)
#               tag "boolean getter"
              @value.send(name2)
            elsif @value.has_key?(name)
              @value[name]
            else
#               tag "value #{@value.inspect} does not have key #{name.inspect}"
              Transaction::PropertyChange::NoValue # we got nothing better
            end
          end
        else
          if @value.has_key?(name)
            @value[name]
          else
            Transaction::PropertyChange::NoValue # we got nothing better
          end
        end
      end

    public  # methods of Structure

      def value v = nil
        return @value if v.nil?
        @value = v
        # We support Hash, or Array or anything simple
      end

      def wrap value, key
#         tag "wrap #{value.class}:#{value}, key = #{key.inspect}, keypath=#{@keypath.inspect}, v.id=#{value.object_id},@v.id=#{@value.object_id}"
        case value
        when Model then value
        when Hash, Array
          return self if value.object_id == @value.object_id
          key = nil if key == :self
          Structure.new(value: value,
                        root: key == :_root ? value : @root,
                        keypath: key && ((@keypath || []) + [key]))
#         when Array then ArrayWrapper.new(@root, key, value, key && ((@keypath || []) + [key]))
        when FalseClass, TrueClass, NilClass, Numeric, String, Symbol
#           tag "RETURNING simpleval #{value.inspect}"
          value
        else
          return self if value.object_id == @value.object_id
          raise 'oops' if key == :_root
          Structure.new(value: value,
                        root: @root,
                        keypath: key && ((@keypath || []) + [key]))
        end
      end

      Corrupteron = [:<<, :clear, :delete, :delete_at, :delete_if, :fill, :insert, :keep_if,
                     :pop, :push, :replace, :shift, :unshift,
                     :store, :update
                    ].
        inject({}) { |hash, el| hash[el] = true; hash }

      # MAKES A MESS!! Reason: Qtruby abuses it too. So we must be careful to pass these on to super!!!
      def method_missing symbol, *args, &block
#         tag "METHOD_MISSING #{symbol.inspect}, current value = #{@value.inspect}"
#         raise 'WTF' if symbol == :tran
        return super unless @value
        case symbol
        when :parent=, :parent then return super
        end
        if symbol.to_s[-1] == '='
          return super if args.length > 3
#           is_setter = @value.respond_to?(symbol)
          key = symbol[0...-1].to_sym
          # Now the value assigned is the very last arg.
          # Example   x[3,4,5] = 34
          # then we have args = [3,4,5,34]
#           tag "applying #{symbol.inspect} to hash #{@value}, n='#{nam[0..-2]}', args=#{args.inspect}"
          # what's to assign:
          if key == :[] #  So s.x[4] = ... something or s[4][:x] = ... or even s.y[2,4] = ....
            if args.length == 3
#               tag "splice operation"
              value = args[2]
              key = args[0, 2]
              prev = @value.clone
              undo_path = @keypath
            else # single key replacement
              raise 'oops' unless args.length == 2
              key, value = args
              prev = calc_prev key
              undo_path = (@keypath || []) + [key]
            end
          else  # other setter like             x.field = value
            if args.length > 1 || !@value.respond_to?(:[]=) && !@value.respond_to?(symbol)
              tag "I CAN'T USE THIS, argcount=#{args.length}, value does not have []= and also not #{symbol}"
              # this will fail, but the errormessage makes more sense:
#               return @value.method_missing(symbol, *args, &block)             requires hack since mm is private!
              return super
            end
            value = args[0]
            prev = calc_prev key
#             tag "other setter (#{key.inspect}), newval = #{value}, prev = #{prev}, @value= #{@value.inspect}"
            undo_path = (@keypath || []) + [key]
          end
          pickup_tran do |tran|
#             tag "recording transaction log"
# IMPORTANT: it is possible that we get here from an undo-operation. So 'assign' must be called, even if the
# transaction is already aborted
            assign(key, value, symbol)
            tran.addPropertyChange(undo_path, prev) unless tran.aborted?
          end
        else
          # another fine mess. Some methods will change @value nevertheless.
          # We must catch ALL of them!!
          last_char = symbol.to_s[-1]
          if (last_char == '!' || Corrupteron[symbol]) && @value.respond_to?(symbol)
#             tag "MODIFIER DETECTED!!!!!!!!!!!!!!!!!!!!!!!!!!!! -> #{symbol}"
            pickup_tran do |tran|
              case symbol # special cases
              when :<<
                raise 'oops' unless args.length == 1 || block
                @value << args[0]
                tran.push(Transaction::PropertyPushed.new(@root, @keypath)) unless tran.aborted?
                return self
              when :push # not the same as <<, you cannot << 1,2 but you can push(1,2)
                raise 'oops' if block
                return self if args.empty?
                @value.push(*args)
                tran.push(Transaction::PropertyPushed.new(@root, @keypath, args.length)) unless tran.aborted?
                return self
              when :delete_at
                raise 'oops' unless args.length == 1 || block
                idx = args[0]
                return self unless @value.has_key?(idx)
                return @value.delete_at(idx) if tran.aborted?
                prev = @value[idx]
                result = @value.delete_at idx
                tran.push(Transaction::PropertySpliced.new(@root, (@keypath ||= []) + [idx], prev))
                return result # , :_root)               if you want to use as struct use your own constructor
              when :delete
                raise 'oops' unless args.length == 1
                # 'delete' works differently for arrays and hashes!
                if Hash === @value
                  # However, the 'abort' will ruin the order this way...   Currently a 'feature'
                  idx = args[0]
                  return self unless @value.has_key?(idx)
                  return @value.delete(idx, &block) if tran.aborted?
                  prev = @value[idx]
                  result = @value.delete(idx, &block)
                  tran.push(Transaction::PropertyDeleted.new(@root, (@keypath ||= []) + [idx], prev))
                  return result # , :_root)               if you want to use as struct use your own constructor
                end
              when :pop
                raise 'oops' unless args.length <= 1 || block
                count = args[0] || 1
                return @value.pop(count) if tran.aborted?               # CANTHAPPEN DUE TO SHORTCUT IN model.rb (fixme??)
                prev = @value.last(count)
                result = @value.pop(count)
                tran.push(Transaction::PropertyPopped.new(@root, @keypath, prev))
                return result # see delete_at
              when :shift # comparable with pop, but then in front
                raise 'oops' unless args.length <= 1 || block
                count = args[0] || 1
                return @value.shift(count) if tran.aborted?
                prev = @value.first(count) # always an array
                result = @value.shift(count)
                tran.push(Transaction::PropertyShifted.new(@root, @keypath, prev))
                return result # see delete_at
              when :unshift # comparable with push, but then in front
                raise 'oops' if block
                return self if args.empty?
                @value.unshift(*args)
                tran.push(Transaction::PropertyUnshifted.new(@root, @keypath, args.length)) unless tran.aborted?
                return self
              when :insert
                raise 'oops' if block || args.empty?
                return self if args.length == 1
                # assume array.                 Array.insert(at, el1, el2 .... )
                # the undo should use Array.slice!(at, elcount)
                # But if 'at' < 0 we get
                #  x = [1, 2, 3, 4]
                #  x.insert(-2, 5, 6) -> [1, 2, 3, 5, 6, 4]
                # the slice is then  x.slice!(at - elcount + 1, elcount)
                return @value.insert(*args) if tran.aborted?
                idx, elcount = args[0], args.length - 1
                @value.insert(*args)
                tran.push(Transaction::PropertyAdded.new(@root, (@keypath ||= []) + [idx], elcount))
                return self
              end
              return @value.send(symbol, *args, &block) if tran.aborted?
              prev = @value.clone
              result = wrap(@value.send(symbol, *args, &block), :_root)
              tran.addPropertyChange(@keypath, prev)
              result
            end
          else
            return super unless args.empty?
            key = last_char == '?' ? symbol[0...-1].to_sym : symbol
#             tag "Apply GETTER #{symbol.inspect}, value=#@value"
            if symbol == :self
              return self if Hash === @value   # spare an unwrap + wrap on a common case
              wrap(@value, symbol)
            elsif @value.respond_to?(symbol) then wrap(@value.send(symbol, *args, &block), symbol)
            else wrap(@value[key], key)
            end
          end
        end
#         tag "OK"              AAAAAAAAAAAARGFHHHHH
      end

      def getter? name
        case name
        when :self, Proc then true
        when Symbol, String then (!@value.respond_to?(:has_key?) || @value.has_key?(name))
        else true
        end
      end

      # To apply the getter, this method must be used.
      def apply_getter name
#         tag "apply_getter(#{name.inspect}), value=#@value"
        if name == :self
          wrap(@value, name)
        elsif Proc === name
          #applying method on the structure (not on hash)
          wrap(name.call(@value), name)
  #         tag "apply getter proc -> #{r.inspect}"
        else
          wrap(@value[name], name)
        end
      end

      def setter? name
        case name
        when Proc then false
        when Symbol, String then (!@value.respond_to?(:has_key?) || @value.has_key?(name)) && !@value.frozen?
        else
          !@value.frozen?
        end
      end

      def apply_setter name, value, sender = nil
#         tag "apply_setter(#{name.inspect}, #{value})"
  #         name = name.to_s
  #         name = name[0...-1] if name[-1] == '?'
        pickup_tran do |tran|
          if tran.aborted?
            assign(name, value)
          else
            prev = calc_prev(name)
            assign(name, value)
            tran.addPropertyChange(name == :self ? @keypath : (@keypath || []) + [name], prev)
          end
        end
      end

      def length
        @value.respond_to?(:length) ? @value.length : 1
      end

      #Note that Hashes will iterate their key as the index. While Array uses the real index.
      # If you use each_with_index on a hash we get el = [key0,value0] and index 0  etc.
      def each_with_index &block
        return to_enum(:each_with_index) unless block
        path = @keypath || []
        if @value.respond_to?(:each_pair)
#           tag "#{@value.inspect} behaves Hash-like, using each_pair"
          index = 0
          @value.each_pair do |key, el|
#             tag "each_pair iteration -> #{index.inspect}, #{el}"
            yield wrap(el, key), index
            index += 1
          end
        elsif @value.respond_to?(:each_with_index)
#           tag "#@value behaves Array-like"
          @value.each_with_index do |el, index|
#             tag "YIELD a new Structure on #{el.inspect}, index = #{index}"
            yield wrap(el, index), index
          end
        else
          yield self, 0
        end
      end

      # Note that for { 3=>35, 23=>2} as s.row(0) will 35 and s.row(1) will be 2.
      def row numeric_key
        if @value.respond_to?(:each_pair)
          i = 0
          @value.each_pair do |k, v|
            return wrap(v, k) if i == numeric_key
            i += 1
          end
        end
        if @value.respond_to?(:[])
          wrap(@value[numeric_key], numeric_key)
        else
          numeric_key == 0 ? @value : nil
        end
      end

      def [] *args
        if args.length == 1
          key = args[0]
#           if key == :self
#             Hash === @value ? self : wrap(@value, :self)
#           else
          wrap(@value[key], key)
#           end
        else
          wrap(@value[*args], args)
        end
      end

      def value2index value
        if @value.respond_to?(:each_pair)
          i = 0
          @value.each_pair do |k, v|
            return i if v == value
            i += 1
          end
          nil
        elsif @value.respond_to?(:find_index)
          @value.find_index(value)
        else
          0
        end
      end

  end

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
anymore.  We just propagate the modelchange to application and it will send
it to all concerned forms.

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

Two complications:
  - changes that cause other attributes to change instead of a single one.
  - the ability to use blocks as getters and setters
  - expensive parts in the keypath

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

Expensive Parts
================

Persistance
============
Assuming that the application is stable enough, a timed save of the rootdata will work
as a persistance trick (or when exiting). We can save 'backups' every 10 minutes or so.
The computer can save let's say 10MB per second so for simplistic apps this should
in fact be more than sufficient.


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

Wrapping and assigning
========================

There is already an identity problem here.
I can say:
  s = x: x, y: y, z: [1,2,3,4]
  s.z[2, 2] = 5
In this case 's.z' returns actually a wrapper around [1,2,3,4] (say s2)
And the assignment will change s2.value which is s.z. However,
internally this records as a change of 'self'. So an abort will reassign
s2.value itself and therefore not s.z
More direct:
  s = x: x, y: y, z: [1,2,3,4]
  s.z.map!{|x|x+1}

That's wrong. What is stored is a keypath and it measures within the rootmodel.
So the abort always works on 's'.  The only problem is the evaluation of the keypath.
The keypath is recorded as [:z, :self]
But obviously it should have been [:z]. Similar that [:self] is really an empty path ([]).
