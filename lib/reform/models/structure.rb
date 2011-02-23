
# Copyright (c) 2010-2011 Eugene Brazwick

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

  A change-index can be an array of fields, like [:y, 0, :y]

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


=====================================================
INTEGRITY KILLER NR 1: array.sort! and array.sort_by!
=====================================================
We need a map then from old sit. to new sit. Can be done using objectids.

=end
  class Structure #< AbstractModel       #          yaml does not really work nice with Qt objects....
     include Model, ModelContext

    private # methods of Structure

      # [parent] owner control, or a wrapped value.
      # [value] the value
      # [qtc] Qt implementor (if parent is a control) or the root-structure otherwise
      # [key]
      def initialize parent, key, value
        @model_parent, @model_key, @model_value = parent, key, value
      end

      # It is very dangerous storing keypaths within an array, as the indices may shift!!
      def inter key, value
#         tag "inter value #{value.inspect}, klass:#{value.class} for key :#{key}"
        case value
        when Hash, Array then Structure.new(self, key, value)
        when Numeric, FalseClass, TrueClass, NilClass, String, Symbol then value
        else
          if value.respond_to?(:model?) && value.model?
#             raise 'blerk' if value.disposed?
            # incorporate the model by setting parent + root + keypath
            value.model_parent = self
            value.model_key = key
#             tag "#{value}.parent := #{self}"
#             tag "oldparent was #{value.parent}"
            value
          else
            Structure.new(self, key, value)
          end
        end
      end

      def model_assign key, value, org_symbol = nil
#         tag "Assign #{key.inspect}, #{value}, currentvalue=#{@model_value.inspect}, keypath=#{@model_keypath.inspect}, value:=#{value.inspect}"
        case key
        when :self
#           tag "#{self} ASSIGN self @model_value := #{value}"
          @model_value = value
          case @model_value
          when Hash
            @model_value.each do |k, v|
#               tag "Checking hash key #{k.inspect}, value = #{v.inspect}"
              @model_value[k] = inter(k, v)
            end
          when Array
            @model_value.each_with_index do |v, k|
              @model_value[k] = inter(k, v)
            end
          end
          raise 'TRYING TO MAKE A MESS????' if @model_value.nil?
        when Array
          @model_value[*key] = inter(key, value)
        else
          org_symbol ||= (key.to_s + '=').to_sym      # the caller sometimes knows this, so we could pass it as option
#           tag "does #@model_value (class #{@model_value.class}) respond_to #{org_symbol.inspect}"
          if org_symbol != :[]= && @model_value.respond_to?(org_symbol)
#             tag "YES, send it"
            @model_value.send(org_symbol, inter(org_symbol, value))
          else
#             tag "NO, apply index @model_value[#{key}] := #{value}"
            @model_value[key] = inter(key, value)
          end
        end
      rescue TypeError => err
        raise err.class, tr("when assigning '#{key}': #{err}"), err.backtrace + caller
#         tag "Assigned #{value}, value is now #{@model_value.inspect}"
      end

      def calc_prev name
#         tag "calc_prev(#{name.inspect})"
        case name
        when :self
          @model_value
        when Symbol
          if @model_value.respond_to?(name)
#             tag "true getter"
            @model_value.send(name)
          else
            name2 = (name.to_s + '?').to_sym
            if @model_value.respond_to?(name2)
#               tag "boolean getter"
              @model_value.send(name2)
            elsif @model_value.has_key?(name)
              @model_value[name]
            else
#               tag "value #{@model_value.inspect} does not have key #{name.inspect}"
              Transaction::PropertyChange::NoValue # we got nothing better
            end
          end
        else
          if @model_value.has_key?(name)
            @model_value[name]
          else
            Transaction::PropertyChange::NoValue # we got nothing better
          end
        end
      end

    public  # methods of Structure

      def model_value v = nil
        return @model_value if v.nil?
        @model_value = v
        # We support Hash, or Array or anything simple
      end

      Corrupteron = [:<<, :clear, :delete, :delete_at, :delete_if, :fill, :insert, :keep_if,
                     :pop, :push, :replace, :shift, :unshift,
                     :store, :update
                    ].
        inject({}) { |hash, el| hash[el] = true; hash }

      # MAKES A MESS!! Reason: Qtruby abuses it too. So we must be careful to pass these on to super!!!
      def method_missing symbol, *args, &block
#         tag "METHOD_MISSING #{symbol.inspect}, current value = #{@model_value.inspect}"
#         raise 'WTF' if symbol == :tran
        return super unless @model_value
        case symbol
        when :model_parent=, :model_parent then return super
        end
        if symbol[-1] == '='
          return super if args.length > 3
#           is_setter = @model_value.respond_to?(symbol)
          key = symbol[0...-1].to_sym
          # Now the value assigned is the very last arg.
          # Example   x[3,4,5] = 34
          # then we have args = [3,4,5,34]
#           tag "applying #{symbol.inspect} to hash #{@model_value}, n='#{nam[0..-2]}', args=#{args.inspect}"
          # what's to assign:
          if key == :[] #  So s.x[4] = ... something or s[4][:x] = ... or even s.y[2,4] = ....
            if args.length == 3  # x[3, 4] = ....
              # In cases of 'splice', if the second arg is an array, it is unpacked.
              # In cases of 'splice' arg2 is the nr of items deleted.
#               tag "splice operation"
              idx0, del_count, value = args
              if value.respond_to?(:length)
                ins_count = value.length
              else
                ins_count = 1
                value = [value]
              end
              key = args[0, 2]
#               oldvals = @model_value[*key]
            else # single key replacement, truly a PropertyChange
              # NO: key can be a range!!
              raise 'oops' unless args.length == 2
              key, value = args
              if Range === key
                idx0 = key.min
                del_count = key.max - idx0 + 1
                if value.respond_to?(:length)
                  ins_count = value.length
                else
                  ins_count = 1
                  value = [value]
                end
              else
                idx0 = key
                del_count = 0
                ins_count = 1
                value = [value]
              end
#               oldvals = @model_value[key]
            end
            # Examples:  x[3,0] = a,b,c    del_count = 0, ins_count = 3, all insert
            #            x3[3,1] = a,b     del_count=1, ins_count=2, 1 update, 1 ins
            #            x3[3,2] = a,b     del_count=2, ins_count=2, pure update
            #            x3[3,2] = a (a not an array!)  del_count=2, ins_count=1, 1 update, 1 delete
            #            x3[3,2] = []      del_count=2, ins_count=0, pure delete
            # we have a propertychange for a whole range of items, if del_count < ins_count
            raise 'oops' unless Array === value
            model_pickup_tran do |tran|
              upd_count = [del_count, ins_count].min
              del_count -= upd_count
              ins_count -= upd_count
              for j in 0...upd_count
                oldval = model_apply_getter(idx0)
                tran.addPropertyChange(self, idx0, oldval) unless tran.aborted?
                model_assign(idx0, value[j])
                idx0 += 1
              end
              if del_count > 0
#                 if del_count == 1    # the caller did x[] == .. so let's pass that on the wrapped value
#                   tran.push(PropertyDeleted.new(self, idx0, @model_value[idx0])) unless tran.aborted?
#                   @model_value.delete_at(idx0)
#                 else
                  unless tran.aborted?
                    oldvals = @model_value[idx, del_count]
                    tran.push(PropertySpliced.new(self, idx0, oldvals))
                  end
                  @model_value[idx0, del_count] = []
#                 end
              end
              if ins_count > 0
                tran.push(PropertyAdded.new(self, idx0, ins_count)) unless tran.aborted?
                @model_value[idx0, 0] = value[upd_count, ins_count]
              end
            end
          else  # other setter like             x.field = value
            if args.length > 1 || !@model_value.respond_to?(:[]=) && !@model_value.respond_to?(symbol)
              tag "I CAN'T USE THIS, argcount=#{args.length}, value does not have []= and also not #{symbol}"
              # this will fail, but the errormessage makes more sense:
#               return @model_value.method_missing(symbol, *args, &block)             requires hack since mm is private!
              return super
            end
            value = args[0]
            oldvals = model_apply_getter(key)
#             tag "other setter (#{key.inspect}), newval = #{value}, prev = #{prev}, @model_value= #{@model_value.inspect}"
            model_pickup_tran do |tran|
  # tran.debug_track!
  #             tag "recording transaction log"
  # IMPORTANT: it is possible that we get here from an undo-operation. So 'assign' must be called, even if the
  # transaction is already aborted
              model_assign(key, value, symbol)
              tran.addPropertyChange(self, key, oldvals) unless tran.aborted?
            end
          end
        else
          # another fine mess. Some methods will change @model_value nevertheless.
          # We must catch ALL of them!!
          last_char = symbol[-1]
          if (last_char == '!' || Corrupteron[symbol]) && @model_value.respond_to?(symbol)
#             tag "MODIFIER DETECTED!!!!!!!!!!!!!!!!!!!!!!!!!!!! -> #{symbol}"
            model_pickup_tran do |tran|
              case symbol # special cases
              when :<<
                raise 'oops' unless args.length == 1 || block
                @model_value << inter(@model_value.length, args[0])
                tran.push(Transaction::PropertyPushed.new(self)) unless tran.aborted?
                return self
              when :push # not the same as <<, you cannot << 1,2 but you can push(1,2)
                raise 'oops' if block
                return self if args.empty?
                args.each do |el|
                  @model_value.push(inter(@model_value.length, el))
                end
                tran.push(Transaction::PropertyPushed.new(self, args.length)) unless tran.aborted?
                return self
              when :delete_at
                raise 'oops' unless args.length == 1 || block
                idx = args[0]
                return self unless @model_value.has_key?(idx)
                return @model_value.delete_at(idx) if tran.aborted?
                # BUG 0027 applies here. May destroy integrity
                oldvals = [@model_value[idx]]
                result = @model_value.delete_at idx
                tran.push(Transaction::PropertySpliced.new(self, idx, oldvals))
                return result # , :_root)               if you want to use as struct use your own constructor
              when :delete
                # BUG 0027 applies here. May destroy integrity
                raise 'oops' unless args.length == 1
                # 'delete' works differently for arrays and hashes!
                if Hash === @model_value
                  # However, the 'abort' will ruin the order this way...   Currently a 'feature'
                  idx = args[0]
                  return self unless @model_value.has_key?(idx)
                  return @model_value.delete(idx, &block) if tran.aborted?
                  prev = @model_value[idx]
#                   tag "Calling #{@model_value}.delete(#{idx.inspect})"
                  result = @model_value.delete(idx, &block)
#                   tag "value is now #{@model_value.inspect}"
                  tran.push(Transaction::PropertyDeleted.new(self, idx, prev))
                  return result # , :_root)               if you want to use as struct use your own constructor
                end
              when :pop
                raise 'oops' unless args.length <= 1 || block
                count = args[0] || 1
                return @model_value.pop(count) if tran.aborted?               # CANTHAPPEN DUE TO SHORTCUT IN model.rb (fixme??)
                prev = @model_value.last(count)
                result = @model_value.pop(count)
                tran.push(Transaction::PropertyPopped.new(self, prev))
                return result # see delete_at
              when :shift # comparable with pop, but then in front
                # BUG 0027 applies here. May destroy integrity
                raise 'oops' unless args.length <= 1 || block
                count = args[0] || 1
                return @model_value.shift(count) if tran.aborted?
                prev = @model_value.first(count) # always an array
                result = @model_value.shift(count)
                tran.push(Transaction::PropertyShifted.new(self, prev))
                return result # see delete_at
              when :unshift # comparable with push, but then in front
                raise 'oops' if block
                return self if args.empty?
                @model_value.unshift(*args)
                unless tran.aborted?
                  tran.push(Transaction::PropertyUnshifted.new(self, args.length))
                end
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
                return @model_value.insert(*args) if tran.aborted?
                idx, elcount = args[0], args.length - 1
                @model_value.insert(*args)
                tran.push(Transaction::PropertyAdded.new(self, idx, elcount))
                return self
              end
              return @model_value.send(symbol, *args, &block) if tran.aborted?
              raise "not implemented yet: total destructors like '#{symbol}'"
              prev = @model_value.clone # BAD IDEA !!
              result = @model_value.send(symbol, *args, &block)
              tran.addPropertyChange(self, :self, prev)
              result
            end
          else
            return super unless args.empty?
            return model_apply_getter(:self) if symbol == :self
            key = last_char == '?' ? symbol[0...-1].to_sym : symbol
#             tag "Apply GETTER #{symbol.inspect}, value=#@model_value"
            if @model_value.respond_to?(:has_key?) && @model_value.has_key?(symbol) then @model_value[key]
            elsif @model_value.respond_to?(symbol) then @model_value.send(symbol, *args, &block)
            else nil
            end
          end
        end
#         tag "OK"              AAAAAAAAAAAARGFHHHHH
      end

      def model_getter? name
        case name
        when :self, Proc then true
        when Symbol, String then (!@model_value.respond_to?(:has_key?) || @model_value.has_key?(name))
        else true
        end
      end

      # To apply the getter, this method must be used.
      def model_apply_getter name
#         tag "model_apply_getter(#{name.inspect}), value=#@model_value"
        case name
        when :self
          Array === @model_value || Hash === @model_value ? self : @model_value
        when :root then model_root
        when Proc
          #applying method on the structure (not on hash)
          name.call(self) #   NOT @model_value, I just said it...
  #         tag "apply getter proc -> #{r.inspect}"
        when Symbol
#           tag "check #@model_value respond_to :#{name}"
          if @model_value.respond_to?(name)
            @model_value.send(name)
          else
            begin
              @model_value[name]
            rescue TypeError
              raise Error, tr("Bad getter '#{name.inspect}' on #{@model_value.class} value, caller = #{caller.join("\n")}")
            end
#             nil
          end
        when Array
          # using recursion
          name.inject(self) do |v, nm|
#             tag "Apply #{nm} on #{(v.respond_to?(:value) ? v.value : v).inspect}, v.root= #{v && v.root}"
            (v && v.model_apply_getter(nm))#.tap{|r| tag " :#{nm} ---> #{(r.respond_to?(:value) ? r.value : r).inspect}"}
          end
        else
          @model_value[name]
        end
      end

      def model_setter? name
        case name
        when Proc then false
        when Symbol, String then (!@model_value.respond_to?(:has_key?) || @model_value.has_key?(name)) && !@model_value.frozen?
        else
          !@model_value.frozen?
        end
      end

      def model_apply_setter name, value, sender = nil, more_args = nil
#         tag "model_apply_setter(#{name.inspect}, #{value}, sender = #{sender})"
  #         name = name.to_s
  #         name = name[0...-1] if name[-1] == '?'
        if Array === name
          sub = name[0...-1].inject(self) { |v, nm| v && v.model_apply_getter(nm) } and
            sub.model_apply_setter(name[-1], value, sender)
          return
        end
        model_pickup_tran(sender) do |tran|
          if tran.aborted?
            model_assign(name, value)
          else
            tran.debug_track! if more_args && more_args[:debug_track]
            prev = calc_prev(name)
            model_assign(name, value)
#             tag "ADDING PROPCHANGE"
            tran.addPropertyChange(name == :self ? @model_keypath : @model_keypath + [name], prev)
          end
        end
      end

      # override
      def length
#         tag "#{self}::length, @model_value=#{@model_value.inspect}"
        @model_value.respond_to?(:length) ? @model_value.length : 1
      end

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

      # Note that for { 3=>35, 23=>2} as s.row(0) will 35 and s.row(1) will be 2.
      def model_row numeric_key
        if @model_value.respond_to?(:each_pair)
          i = 0
          @model_value.each_pair do |k, v|
            return v if i == numeric_key
            i += 1
          end
        end
        if @model_value.respond_to?(:[])
          @model_value[numeric_key]
        else
          numeric_key == 0 ? self : nil
        end
      end

      def [] *args
        if args.length == 1
          key = args[0]
#           if key == :self
#             Hash === @model_value ? self : wrap(@model_value, :self)
#           else
          @model_value[key]
#           end
        else
          @model_value[*args]
        end
      end

      # this method is used to set the proper row, if 'value' is connected to it.
      # Now the problem is that Hashes and Arrays can connect to their index or their value.
      #
      # IMPORTANT saying 'key_connector:id' is not the same as leaving it the default (also :id)
      # Because this switches on locating the value by key
      #
      def model_value2index value, view
        return 0 if value.nil?
        key_connector = view.key_connector
        key = model_value2key(value, view) or
          key ||= value if key_connector # if key-lookup is enforced,
#         tag "value2index, key_connector=#{key_connector}, key = #{key.inspect}, value was #{(value.respond_to?(:value) ? value.value : value).inspect}"
        if @model_value.respond_to?(:each_key)
#           tag "HASH case"
          if key
            @model_value.each_key.find_index(key)
          elsif @model_value.respond_to?(:each_pair)
#             tag "Using each_pair"
            @model_value.each_pair.find_index { |k, v| v == value }
          end
          @model_value.each_key.find_index(value)
        elsif @model_value.respond_to?(:find_index)
#           tag "ARRAY case"
          return nil if @model_4value.empty?
          key = value if !key && model_value2key(@model_value[0], view) # force the use of a key if this seems to be how it should be done.
              # but it is higher heuristics
          if key
            return key if key_connector == :numeric_index
            @model_value.find_index do |value|
#               tag "Comparing value2key #{value2key(value, view).inspect}, with key #{key.inspect}"
              model_value2key(value, view) == key
            end #.tap{|r|tag "find_index -> #{r.inspect}"}
          else
            @model_value.find_index(value)
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

      # important override
      def respond_to? symbol
        # only the getters are really covered here.
        @model_value.respond_to?(symbol) || Hash === @model_value && @model_value[symbol] || super
      end

      def build &block
        @model_value = {}
#         tag "build, value := {}, + instance eval"
        instance_eval(&block)
        self
      end

      #override
      def model_mimeType
        tag "#{self}::model_mimeType, getter? #{model_getter?(:model_mimeType)}, value=#{@model_value.inspect}"
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
