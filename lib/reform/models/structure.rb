
# Copyright (c) 2010 Eugene Brazwick

class Array
  def has_key? i
    Fixnum === i && (i >= 0 && i < length || i < 0 && -i <= length)
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
  class Structure #< AbstractModel       #          yaml does not really work nice with Qt objects....
     include Model, ModelContext
#      include ModelContext

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
        super() ##!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#         tag "new #{self}, args = #{args.inspect}"
        if args.length == 1 && Control === args[0]
          @parent = @args[0]
          raise "TOTAL CORRUPTION" unless !args[0].model? || args[0].root
          @root = if args[0].model? then args[0].root else self end
        else
          @root = self
        end
#         tag "INITIALIZE ,args = #{args.inspect}"
        if args.length == 1
          args = args[0]
          if Hash === args && args.has_key?(:keypath)
  #         tag "#{self}.new(#{parent.inspect}, gp=#{qtc}"
            @root = args[:root] || self
            @keypath = args[:keypath] || []
            assign :self, args[:value]
            raise "BOGO keypath, caller = #{caller.join("\n")}" if @keypath == [nil] || !(Array === @keypath)
            raise 'TRYING TO MAKE A MESS????, keypath given but not value' if @value.nil?
          else
            @keypath = []
            assign :self, args
          end
        else
#         @root = self
# #         tag "setup @value := #{args}"
          @keypath = []
          assign :self, args
        end
        raise 'TRYING TO MAKE A MESS????' if @value.nil?
        raise 'TRYING TO MAKE A MESS????' if @value.respond_to?(:model?) && @value.model?
        raise 'TRYING TO MAKE A MESS????' if @root.nil? || @root != root
#         tag "INIT #{self} OK, @root = #@root, root = #{self.root}"
      end

      # It is very dangerous storing keypaths within an array, as the indices may shift!!
      def inter value, key
#         tag "inter value #{value.inspect}, klass:#{value.class} for key :#{key}"
        case value
        when Hash, Array then Structure.new(value: value, keypath: @keypath + [key], root: @root)
        when Numeric, FalseClass, TrueClass, NilClass, String, Symbol then value
        else
          if value.respond_to?(:model?) && value.model?
#             raise 'blerk' if value.disposed?
            # incorporate the model by setting parent + root + keypath
            value.root = @root
            value.keypath = @keypath + [key]
#             tag "#{value}.parent := #{self}"
#             tag "oldparent was #{value.parent}"
            value.parent = self
            value
          else
            Structure.new(value: value, keypath: @keypath + [key], root: @root)
          end
        end
      end

      def assign key, value, org_symbol = nil
#         tag "Assign #{key.inspect}, #{value}, currentvalue=#{@value.inspect}, keypath=#{@keypath.inspect}, value:=#{value.inspect}"
        case key
        when :self
#           tag "#{self} ASSIGN self @value := #{value}"
          @value = value
          case @value
          when Hash
            @value.each do |k, v|
#               tag "Checking hash key #{k.inspect}, value = #{v.inspect}"
              @value[k] = inter(v, k)
            end
          when Array
            @value.each_with_index do |v, k|
              @value[k] = inter(v, k)
            end
          end
          raise 'TRYING TO MAKE A MESS????' if @value.nil?
        when Array
          @value[*key] = inter(value, key)
        else
          org_symbol ||= (key.to_s + '=').to_sym      # the caller sometimes knows this, so we could pass it as option
#           tag "does #@value (class #{@value.class}) respond_to #{org_symbol.inspect}"
          if org_symbol != :[]= && @value.respond_to?(org_symbol)
#             tag "YES, send it"
            @value.send(org_symbol, inter(value, org_symbol))
          else
#             tag "NO, apply index @value[#{key}] := #{value}"
            @value[key] = inter(value, key)
          end
        end
      rescue TypeError => err
        raise err.class, tr("when assigning '#{key}': #{err}"), err.backtrace + caller
#         tag "Assigned #{value}, value is now #{@value.inspect}"
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

      attr_accessor :parent

      def value v = nil
        return @value if v.nil?
        @value = v
        # We support Hash, or Array or anything simple
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
              undo_path = @keypath + [key]
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
            undo_path = @keypath + [key]
          end
          pickup_tran do |tran|
# tran.debug_track!
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
                @value << inter(args[0], @value.length)
                tran.push(Transaction::PropertyPushed.new(@root, @keypath)) unless tran.aborted?
                return self
              when :push # not the same as <<, you cannot << 1,2 but you can push(1,2)
                raise 'oops' if block
                return self if args.empty?
                args.each do |el|
                  @value.push(inter(el, @value.length))
                end
                tran.push(Transaction::PropertyPushed.new(@root, @keypath, args.length)) unless tran.aborted?
                return self
              when :delete_at
                raise 'oops' unless args.length == 1 || block
                idx = args[0]
                return self unless @value.has_key?(idx)
                return @value.delete_at(idx) if tran.aborted?
                # BUG 0027 applies here. May destroy integrity
                prev = @value[idx]
                result = @value.delete_at idx
                tran.push(Transaction::PropertySpliced.new(@root, @keypath + [idx], prev))
                return result # , :_root)               if you want to use as struct use your own constructor
              when :delete
                # BUG 0027 applies here. May destroy integrity
                raise 'oops' unless args.length == 1
                # 'delete' works differently for arrays and hashes!
                if Hash === @value
                  # However, the 'abort' will ruin the order this way...   Currently a 'feature'
                  idx = args[0]
                  return self unless @value.has_key?(idx)
                  return @value.delete(idx, &block) if tran.aborted?
                  prev = @value[idx]
                  result = @value.delete(idx, &block)
                  tran.push(Transaction::PropertyDeleted.new(@root, @keypath + [idx], prev))
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
                # BUG 0027 applies here. May destroy integrity
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
                STDERR.puts "array integrity goes down the drain. BUG 0027 strikes!"
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
                STDERR.puts "array integrity goes down the drain. BUG 0027 strikes!"
                idx, elcount = args[0], args.length - 1
                @value.insert(*args)
                tran.push(Transaction::PropertyAdded.new(@root, @keypath + [idx], elcount))
                return self
              end
              return @value.send(symbol, *args, &block) if tran.aborted?
              prev = @value.clone
              result = @value.send(symbol, *args, &block)
              tran.addPropertyChange(@keypath, prev)
              result
            end
          else
            return super unless args.empty?
            return apply_getter(:self) if symbol == :self
            key = last_char == '?' ? symbol[0...-1].to_sym : symbol
#             tag "Apply GETTER #{symbol.inspect}, value=#@value"
            if @value.respond_to?(:has_key?) && @value.has_key?(symbol) then @value[key]
            elsif @value.respond_to?(symbol) then @value.send(symbol, *args, &block)
            else nil
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
        case name
        when :self
          Array === @value || Hash === @value ? self : @value
        when :root then root
        when Proc
          #applying method on the structure (not on hash)
          name.call(@value)
  #         tag "apply getter proc -> #{r.inspect}"
        when Symbol
          if @value.respond_to?(name)
            @value.send(name)
          else
            begin
              @value[name]
            rescue TypeError
              raise Error, tr("Bad getter '#{name.inspect}' on #{@value.class} value, caller = #{caller.join("\n")}")
            end
#             nil
          end
        when Array
          # using recursion
          name.inject(self) do |v, nm|
#             tag "Apply #{nm} on #{(v.respond_to?(:value) ? v.value : v).inspect}, v.root= #{v && v.root}"
            (v && v.apply_getter(nm))#.tap{|r| tag " :#{nm} ---> #{(r.respond_to?(:value) ? r.value : r).inspect}"}
          end
        else
          @value[name]
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

      def apply_setter name, value, sender = nil, more_args = nil
#         tag "apply_setter(#{name.inspect}, #{value}, sender = #{sender})"
  #         name = name.to_s
  #         name = name[0...-1] if name[-1] == '?'
        if Array === name
          sub = name[0...-1].inject(self) { |v, nm| v && v.apply_getter(nm) } and
            sub.apply_setter(name[-1], value, sender)
          return
        end
        pickup_tran(sender) do |tran|
          if tran.aborted?
            assign(name, value)
          else
            tran.debug_track! if more_args && more_args[:debug_track]
            prev = calc_prev(name)
            assign(name, value)
#             tag "ADDING PROPCHANGE"
            tran.addPropertyChange(name == :self ? @keypath : @keypath + [name], prev)
          end
        end
      end

      # override
      def length
#         tag "#{self}::length, @value=#{@value.inspect}"
        @value.respond_to?(:length) ? @value.length : 1
      end

      #Note that Hashes will iterate their key as the index. While Array uses the real index.
      # If you use each_with_index on a hash we get el = [key0,value0] and index 0  etc.
      def each_with_index &block
        return to_enum(:each_with_index) unless block
        path = @keypath
        if @value.respond_to?(:each_pair)
#           tag "#{@value.inspect} behaves Hash-like, using each_pair"
          index = 0
          @value.each_pair do |key, el|
#             tag "each_pair iteration -> #{index.inspect}, #{el}"
            yield el, index
            index += 1
          end
        elsif @value.respond_to?(:each_with_index)
#           tag "#@value behaves Array-like"
          @value.each_with_index do |el2, index2|
#             tag "YIELD a new Structure on #{el.inspect}, index = #{index}"
            yield el2, index2
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
            return v if i == numeric_key
            i += 1
          end
        end
        if @value.respond_to?(:[])
          @value[numeric_key]
        else
          numeric_key == 0 ? self : nil
        end
      end

      def [] *args
        if args.length == 1
          key = args[0]
#           if key == :self
#             Hash === @value ? self : wrap(@value, :self)
#           else
          @value[key]
#           end
        else
          @value[*args]
        end
      end

#       def value2index value
#         if @key2index then @key2index[SimpleModel::value2key(value)] else 0 end
#       end

      # this method is used to set the proper row, if 'value' is connected to it.
      # Now the problem is that Hashes and Arrays can connect to their index or their value.
      #
      # IMPORTANT saying 'key_connector:id' is not the same as leaving it the default (also :id)
      # Because this switches on locating the value by key
      #
      def value2index value, view
        return 0 if value.nil?
        key_connector = view.key_connector
        key = value2key(value, view) or
          key ||= value if key_connector # if key-lookup is enforced,
#         tag "value2index, key_connector=#{key_connector}, key = #{key.inspect}, value was #{(value.respond_to?(:value) ? value.value : value).inspect}"
        if @value.respond_to?(:each_key)
#           tag "HASH case"
          if key
            @value.each_key.find_index(key)
          elsif @value.respond_to?(:each_pair)
#             tag "Using each_pair"
            @value.each_pair.find_index { |k, v| v == value }
          end
          @value.each_key.find_index(value)
        elsif @value.respond_to?(:find_index)
#           tag "ARRAY case"
          return nil if @value.empty?
          key = value if !key && value2key(@value[0], view) # force the use of a key if this seems to be how it should be done.
              # but it is higher heuristics
          if key
            return key if key_connector == :numeric_index
            @value.find_index do |value|
#               tag "Comparing value2key #{value2key(value, view).inspect}, with key #{key.inspect}"
              value2key(value, view) == key
            end #.tap{|r|tag "find_index -> #{r.inspect}"}
          else
            @value.find_index(value)
          end
        else
          0
        end
      end

      # Qt::Base overrides this, so we must overoverride it
      def << value
        self.method_missing(:<<, value)
      end

      # returns the data to send to the external connector if the index changes
      # In case of arrays this is the value, UNLESS the record has a method id.
      # In case of a hash this is the value, only if the values have a method 'id'
      #
      # This is the reverse of value2index
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
      def index2value numeric_idx, view
        if @value.respond_to?(:keys)
          key = @value.keys[numeric_idx]
          r = @value[key]
#           tag "keys detected, r = #{r}, value2key(#{r}) == #{value2key(r,view)} index2value[#{numeric_idx}] -> #{value2key(r,view) ? r : key}"
          value2key(r, view) ? r : key
        elsif @value.respond_to?(:[])
          return numeric_idx if view.key_connector == :numeric_index
#           tag "arraylike, index2value[#{numeric_idx}] -> #{@value[numeric_idx]}"
          r = @value[numeric_idx]
          view.key_connector ? value2key(r, view) || numeric_idx : r
#           value2key(r, view) ? numeric_idx : r
        else
#           tag "non enumerable value, return #@value as is"
          @value
        end
      end

      # important override
      def respond_to? symbol
        # only the getters are really covered here.
        @value.respond_to?(symbol) || Hash === @value && @value[symbol] || super
      end

      def build &block
        @value = {}
#         tag "build, value := {}, + instance eval"
        instance_eval(&block)
        self
      end

      #override
      def mimeType
        tag "#{self}::mimeType, getter? #{getter?(:mimeType)}, value=#{@value.inspect}"
        getter?(:mimeType) ? apply_getter(:mimeType) : super
      end

      def to_yaml(*args)
        # sooo sneaky...
#         tag "#{@value.inspect}::to_yaml"
        @value.to_yaml(*args)
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
