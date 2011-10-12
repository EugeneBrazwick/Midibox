
# $VERBOSE = true

require 'pp'

# fully persistent version of structure.rb
# And automatically persistent.

=begin

  rstores cannot be initialized with data.
  A special program should do this.
  'new' will connect to the rstore and hence a completely filled instance
  is always immediately at your service.

  rstore will use a configurable backend, default gdbm 
  rstore v1 is transaction save, provided the backend is. gdbm is NOT!!!
  The data may get corrupted if
  the application crashes or in all other cases where a transaction is
  partly executed.


  GARBAGE COLLECTION
  ==================
  the database has no idea about which nodes can be reached from the root!
  Therefor it must be periodically scanned and cleaned using a true GC.
  To do this use 'compact' now and then.

=============================
  MAD SCIENTIST ALERT!!!!
=============================
  for the art of programming the author made sure that RStoreNode cannot be
  easily distinguished from what it is wrapping...
  See the specs. It seems to work even though Module#=== and RStoreNode#class
  are now hacked and slighlty unreliable.

==================================
  ANTISPECS
  hashkeys must be string or symbol
  methods should not change internal state  
==================================
=end

module Reform
  class RStoreNode
  end
end

class Module
  alias :old_eqeqeq :'==='

  def === obj
    if obj.instance_of?(Reform::RStoreNode) && self === obj.model_value
      true
    else
      old_eqeqeq(obj)
    end
  end
end

require 'reform/model'

module Reform

# rstorenode is the basic wrapper around all complex objects.
# it used objectids to store itself on disk if used as a component
# of another rstore objects. Exceptions are simple objects as 
# numbers and strings.
# Complex objects are stored where the oid is the key and the
# Marshal-ed value.
  class RStoreNode
    include Model

      RSTORE_ATTR_SUFFIX = '_rstore_oid'
      RSTORE_ATTR_SUFFIX_LEN = RSTORE_ATTR_SUFFIX.length

      # when RStoreNodes within an Array are marshalled, the only thing stored are OidRefs
      # and we only need a marked Array by calling it OidRefs.
      # the following is not the same as OidRefs = Array obviously.
      # OidRefs should be interpreted as Array of all OidRef elements
      class OidRefs < Array
      end

      # And this is for hybrid arrays, that contain complex and simple class elements.
      # However we can also store these in a class or hash when the attributenames
      # are converted (right after loading).
      # They should only ever be stored from hybrid arrays though.
      class OidRef
        private
          def initialize oid
            @oid = oid
          end
        public
          attr :oid
      end

    private # RStoreNode methods

      # Basic model constructor
      # +parent+ is the parent model and +parent+.+key+ should refer to this node again
      # +value+ is the object or array or hash to wrap
      # +oid+ is the oid in the rstore.  
      # This is an internal method, do not call directly
      def initialize parent, key, value, oid
        raise "BOGO key #{key.inspect}" if !(nil == key || Symbol === key || Integer === key && key < 10_000_000)
        raise 'arg' if Class === parent
        @model_parent, @model_key, @model_value = parent, key, value
#         tag "#{self}.new, parent=#{@model_parent}, key=#{key.inspect}, value=#{value}, oid=#{oid}"
#         raise 'BOGO' unless value             Sometimes assigned later on
        @rstore_oid = oid
      end

      # override, assign a key within the model
      def model_assign key, value, method_symbol = nil
#        tag "model_assign[#{key}] := #{value.inspect}"
#         raise 'WTF' if value.nil?         nothing wrong with a[2] = nil etc.
        raise '?' if RStoreNode::rstore_atom?(@model_value)
        if RStoreNode.rstore_atom?(value)
          val = value
        else
          val = RStoreNode::rstore_inter(key, value, self, rstore_rstore)
        end
        case @model_value
        when Array, Hash
          @model_value[key] = val
        else
          @model_value.send((key.to_s + '=').to_sym, val)
        end
#         tag "model_value is now #{@model_value.inspect}"
      end

      # returns true if the value is not a complex object. 
      # complex object within a node must become nodes themselves!
      def self.rstore_atom?(value)
        case value
        # RStoreNode is not one of them!!! These classes are basicly stored 'raw'!
        # RStoreNode is NEVER stored. Instead it is converted in a OidRef or even OidRefs or
        # the hashkey is tweaked
        when Numeric, FalseClass, TrueClass, NilClass,
             String, Symbol, Range, Regexp, OidRefs
          true
        else
          false
        end
      end

=begin
  3             -> 3
  employee(age: 43, name: 'E. Brazwick') ->  RStoreNode(rstore_oid: generated, val: employee(...))
  [empl1, empl2, empl3] -> RStoreNode([RStoreNode(rstore_oid:, val: empl1), .....)
  [empl1, empl1, empl1] -> RStoreNode([RStoreNode(rstore_oid:, val: empl1), .....)
                           with 3 different nodes, but each has the same oid!
=end
      # this is the place where rstore contents is gathered and stored
      def self.rstore_wrap key, value, parent, rstore
#        tag "rstore_inter(#{key}, #{value}), id = #{value.object_id}"
        case value
        when Hash
          value.each do |k, v|
            #raise "bad key #{k.inspect} within value to wrap: #{value.inspect}" unless Symbol === k || String === k
            value[k] = rstore_inter(k, v, parent, rstore) unless rstore_atom?(v)
          end
        when Array
          value.each_with_index do |v, k|
            value[k] = rstore_inter(k, v, parent, rstore) unless rstore_atom?(v)
          end
        else
          if value.respond_to?(:model_has_own_storage?) && value.model_has_own_storage?
#            tag "kind of mounted model '#{value}' detected, not stored!!!"
            value.model_parent = parent
            value.model_key = key
            rstore.rstore_assign_oid(oid, value) if need_ospace_storing
            return value
          end
#           tag "interring other kind of instance #{value}"
          ivs = value.instance_variables
          ivs.each do |iv|
            v = value.instance_variable_get(iv)
            unless rstore_atom?(v)
              r = rstore_inter(iv, v, parent, rstore)
#               tag "complex attrib handled, now #{value}.#{iv} := #{r.inspect}"
              value.instance_variable_set(iv, r)
            end
          end
        end
      end

      def self.rstore_inter key, value, parent, rstore
#         tag "returning from rstore_inter, got oid #{oid}"
        return value if rstore_atom?(value) || RStoreNode === value
        need_ospace_storing = false
        if oid = rstore.objectspace[id = value.object_id]
	  rv = rstore.revspace[oid] and return rv
	else
          oid = rstore.rstore_gen_oid(value)
          need_ospace_storing = true
        end
	rstore_wrap key, value, parent, rstore
        rv = RStoreNode.new(parent, key, value, oid)
        if need_ospace_storing
#           tag "inter stores new oid #{oid}"
          rstore.rstore_assign_oid oid, value
	  rstore.revspace[oid] = rv
        end
	rv
      end # def rstore_inter

      # IMPORTANT: copie from structure.rb
      # We could reimplement structure as an rstore with a particular backend.
      # This includes handling of self[i] = val
      def handle_splices *args
#        tag "handle_splices #{self}::[]=#{args.inspect}"
        if args.length == 3  # x[3, 4] = ....
          # In cases of 'splice', if the last arg is an array, it is unpacked.
          # In cases of 'splice' arg2 is the nr of items deleted.
#               tag "splice operation"
          idx0, del_count, value = args
          value = [value] unless value.respond_to?(:length)
          key = args[0, 2]
#               oldvals = @model_value[*key]
        else 
#          tag "single key replacement,can be range"
          raise 'oops' unless args.length == 2
          key, value = args
          if Range === key
            idx0 = key.min
            del_count = key.max - idx0 + 1
            value = [value] unless value.respond_to?(:length)
          else
            idx0 = key
            del_count = 1
            value = [value]
#             tag "arrayfying value"
          end
#               oldvals = @model_value[key]
        end
        ins_count = value.length
        # Examples: x=[0,1,2,3]  x[2..99] = 'oops' -> x := [0,1, 'oops']
        length = @model_value.length
#         tag "ins_count=#{ins_count}, del_count=#{del_count}, l=#{length}, idx=#{idx0}"
        del_count = [0, length - idx0].max if idx0 + del_count > length
        # nr of implicit nils added:
        nil_count = idx0 > length ? idx0 - length : 0
        raise 'argg' if nil_count > 0 && del_count > 0
        # x3 is here for example [0,1,2,3,4,5,6,7,8,9]
        # Examples:  x[3,0] = a,b,c    del_count = 0, ins_count = 3, all insert
        #            x3[3,1] = a,b     del_count=1, ins_count=2, 1 update, 1 ins
        #            x3[3,2] = a,b     del_count=2, ins_count=2, pure update
        #            x3[3,2] = a (a not an array!)  del_count=2, ins_count=1, 1 update, 1 delete
        #            x3[3,2] = []      del_count=2, ins_count=0, pure delete
        #            x3[3,99] = a.     del_count=7, ins_count=1
        # effectively equal to x3[3,7] = a
        # we have a propertychange for a whole range of items, if del_count < ins_count
        raise 'oops' unless Array === value
        model_pickup_tran do |tran|
          upd_count = del_count < ins_count ? del_count : ins_count
          del_count -= upd_count
          ins_count -= upd_count
#          tag "upd_count=#{upd_count},del_count=#{del_count},ins_count=#{ins_count}"
          # one by one
          for j in 0...upd_count
            oldval = @model_value[idx0]
            tran.addPropertyChange(self, idx0, oldval) unless tran.aborted?
#            tag "calling model_assign(#{idx}, #{value[j].inspect}"
            model_assign(idx0, value[j])
            idx0 += 1
          end
          if del_count > 0
#                 if del_count == 1    # the caller did x[] == .. so let's pass that on the wrapped value
#                   tran.push(PropertyDeleted.new(self, idx0, @model_value[idx0])) unless tran.aborted?
#                   @model_value.delete_at(idx0)
#                 else
            unless tran.aborted?
#                 tag "idx=#{idx0},del_count=#{del_count}"
              oldvals = @model_value[idx0, del_count]
              tran.push(Transaction::PropertySpliced.new(self, idx0, oldvals))
            end
            @model_value[idx0, del_count] = []
#                 end
          end
          if ins_count > 0
            tran.push(Transaction::PropertyAdded.new(self, idx0 - nil_count, ins_count + nil_count)) unless tran.aborted?
#             tag "inserting at #{idx0}, value[#{upd_count}, #{ins_count}], = #{value[upd_count, ins_count].inspect}"
            @model_value[idx0, 0] = value[upd_count, ins_count]
#             tag "modval is now #{@model_value.inspect}"
          end
        end # tran
      end # handle_splices

      def handle_hash_key_op(*args)
        # it is not possible to delete keys here!
#         tag "handle_hash_key_op #{self}::[]=#{args.inspect}"
#           tag "single key replacement,can be range"
        raise 'oops' unless args.length == 2
        key, value = args
        is_insert = @model_value.value?(key)
        model_pickup_tran do |tran|
          unless tran.aborted?
            if is_insert
              tran.push(PropertyAdded.new(self, key))
            else
              oldval = @model_value[key]
              tran.addPropertyChange(self, key, oldval)
  #             tag "calling model_assign(#{idx}, #{value[j].inspect}"
            end
          end
          model_assign(key, value)
        end # tran
      end # handle_hash_key_op
      
      Corrupteron = [:<<, :clear, :delete, :delete_at, :delete_if, :fill, :insert, :keep_if,
                     :pop, :push, :replace, :shift, :unshift,
                     :store, :update
                    ].inject({}) { |hash, el| hash[el] = true; hash }
      # so each method mentioned is a key within the Corrupteron hash
      
      def handle_corrupteron(symbol, *args, &block)
        model_pickup_tran do |tran|
          case symbol # special cases
          when :<<
            raise 'oops' unless args.length == 1 || block
            @model_value << RStoreNode.rstore_inter(@model_value.length, args[0], self, rstore_rstore)
#             tag "did <<, model_value is now #{@model_value.inspect}"
            tran.push(Transaction::PropertyPushed.new(self)) unless tran.aborted?
            return self
          when :delete
            # BUG 0027 applies here. May destroy integrity
            raise 'oops' unless args.length == 1
            # 'delete' works differently for arrays and hashes!
            case @model_value
	    when Hash
              idx = args[0]
              return @model_value.default(idx) unless @model_value.has_key?(idx)
              return @model_value.delete(idx, &block) if tran.aborted?
              prev = @model_value[idx]
#                   tag "Calling #{@model_value}.delete(#{idx.inspect})"
              result = @model_value.delete(idx, &block)
#                   tag "value is now #{@model_value.inspect}"
              tran.push(Transaction::PropertyDeleted.new(self, idx, prev))
              return result # , :_root)               if you want to use as struct use your own constructor
	    when Array
              return @model_value.delete(idx, &block) if tran.aborted?
	      idx = @model_value.find_index(args[0])
#	      tag "located idx #{idx} in array for 'delete'"
	      return block ? block.call : nil unless idx
#	      tag "idx exists, execute delete and push tranpropchange"
              prev = @model_value[idx]
              result = @model_value.delete(args[0], &block)
#	      tag "mv is now #@model_value"
              tran.push(Transaction::PropertyDeleted.new(self, idx, prev))
              return result
            end
          when :delete_at
            raise 'oops' unless args.length == 1 && !block
            # 'delete' works differently for arrays and hashes!
	    idx = args[0]
	    if @model_value.respond_to?(:has_key?)
	      return nil unless @model_value.has_key?(idx)
	    else # array
	      l = @model_value.length
	      idx = l + idx if idx < 0
	      return nil if idx >= l
	    end
	    return @model_value.delete_at(idx) if tran.aborted?
            prev = @model_value[idx]
            #tag "Calling #{@model_value}.delete_at(#{idx.inspect})"
            result = @model_value.delete_at(idx)
            #tag "value is now #{@model_value.inspect}"
	    tran.push(Transaction::PropertyDeleted.new(self, idx, prev))
	    return result
	  when :pop
	    raise 'oops' unless args.length <= 1 || block
	    count = args[0] || 1
	    return @model_value.pop(count) if tran.aborted?
	    prev = @model_value.last(count)
	    result = @model_value.pop(count)
	    tran.push(Transaction::PropertyPopped.new(self, prev))
	    return result
	  when :push # not the same as <<, you cannot << 1,2 but you can push(1,2)
	    raise 'oops' if block
	    return self if args.empty?
	    args.each do |el|
	      @model_value.push(RStoreNode::rstore_inter(@model_value.length, el, self, rstore_rstore))
	    end
	    tran.push(Transaction::PropertyPushed.new(self, args.length)) unless tran.aborted?
	    return self
	  when :insert
	    raise 'oops' if block || args.empty?
	    return self if args.length == 1
	    return @model_value.insert(*args) if tran.aborted?
	    idx, elcount = args[0], args.length - 1
	    @model_value.insert(*args)
	    tran.push(Transaction::PropertyAdded.new(self, idx, elcount))
	    return self
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
          end
          return @model_value.send(symbol, *args, &block) if tran.aborted?
          # We must make sure the abort restores the situation
          # it should NOT replace 'self' with the clone.
          # Maybe a special propch can work here 'TotalReplaceOfContents'
          # to restore by doing a 'foreach property' kind of operation
          prev = @model_value.clone
          result = @model_value.send(symbol, *args, &block)
          tran.push(Transaction::TotalReplacement.new(self, prev))
          result
        end
      end

      def self.rstore_array2hash value, rstore
#         tag "value is Array"
        no_atoms, all_atoms = true, true
        value.each do |el|
          if rstore_atom?(el) then no_atoms = false else all_atoms = false end 
        end
        return value if all_atoms  # this includes []
        return OidRefs.new(value) if no_atoms
        # when replacing values with oids, how to differentiate
        # with a plain value equal to some oid?
        # for hashes we mark the key
        a = []
        value.each do |v|
          if rstore_atom?(v) || OidRef === v
            a << v
          else 
            case v
            when RStoreNode
              a << OidRef.new(v.rstore_oid)
            else
              objectspace = rstore.objectspace
              unless oid = objectspace[id = v.object_id]
                oid = rstore.rstore_gen_oid(v)
                rstore.rstore_assign_i oid, v
              end
              a << OidRef.new(oid)
            end
          end
        end # each
#             tag "ready to marshal mixed node array: #{a.inspect}"
        a
      end
        
      def self.rstore_hash2hash value, rstore
#         tag "value is Hash"
        return value if value.all? { |k, v| rstore_atom?(v) }
        h = {}
        value.each do |k, v|
          if rstore_atom?(v)
            h[k] = v
          else
            # mark key so loader knows this is an oid:
            key = (k.to_s + RSTORE_ATTR_SUFFIX).to_sym
            case v
            when OidRef
              h[key] = v.oid
            when RStoreNode
              h[key] = v.rstore_oid
            else
              unless oid = rstore.objectspace[id = v.object_id]
                oid = rstore.rstore_gen_oid(v)
#                 tag "rstore_value2hash creates new oid #{oid}"
                rstore.rstore_assign_i oid, v
              end
              h[key] = oid
            end
          end
        end
        h
      end
      
      def method_missing(symbol, *args, &block)
#        tag "#{self}::METHOD_MISSING #{symbol.inspect}, current value = #{@model_value.inspect}"
        raise 'WTF' if @model_value.nil?
        case last_char = symbol.to_s[-1]
        when '='
#          tag "test for splicing, args.length = #{args.length}"
          if symbol == :[]= #  So s.x[4] = ... something or s[4][:x] = ... or even s.y[2,4] = ....
            return handle_hash_key_op(*args) if Hash === @model_value
            return handle_splices(*args)
          end # key <> []
          return super if args.length > 1
          value = args[0]
#          tag "value to assign = #{value.inspect}"
          key = symbol[0...-1].to_sym # !
          oldval = model_apply_getter(key)
          model_pickup_tran do |tran|
            model_assign(key, value, symbol)
#            tag "addPropertyChange(#{self}, #{key.inspect}, oldval= #{oldval.inspect})"
            tran.addPropertyChange(self, key, oldval) unless tran.aborted?
#            tag "COMMITTING!!!!!!!!!!!!!!!!!!"
          end
          return nil
        when '!' # always treat as changer 
          return handle_corrupteron(symbol, *args, &block) if @model_value.respond_to?(symbol)
        end
        if Corrupteron[symbol] && @model_value.respond_to?(symbol)
          return handle_corrupteron(symbol, *args, &block) 
        end
        # PARANOIA check for things that should definetely be methods
        if symbol[0, 7] == 'rstore_' || symbol[0, 6] == 'model_'  || symbol.to_s.to_i != 0 # how weird can it get?? #|| symbol == :key
          raise "oh no! method #{symbol} should really exist!" 
        end
        return self if symbol == :self && args.empty?
#        tag "Now use #@model_value to apply #{symbol} on"
        key = last_char == '?' ? symbol[0...-1].to_sym : symbol
        has_key = @model_value.respond_to?(:has_key?) && args.empty? && @model_value.has_key?(symbol)
        rv = if has_key then @model_value[key]
        elsif @model_value.respond_to?(symbol) then @model_value.send(symbol, *args, &block)
        else nil
        end
#	tag "rv=#{rv}"
        if OidRef === rv
	  if v = rstore_rstore.revspace[oid = rv.oid] 
	    rv = v
	  else
	    rv = rstore_rstore.rstore_oid2value(oid)
#	    tag "and return a new wrapper!"
	    rv = RStoreNode.new(self, symbol, rv, oid)
	    rstore_rstore.revspace[oid] = rv
	  end
          # Now remove the OidRef
          if has_key
            @model_value[key] = rv
          else
            assigner = (symbol.to_s + '=').to_sym
            @model_value.send(assigner, rv) if @model_value.respond_to?(assigner)
          end
        end
#	tag "method_missing #{symbol} -> rv #{rv}"
        rv
      end # def method_missing

      def model_row_i numeric_key
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

    public # methods of RStoreNode

      attr :model_value
      attr :model_key # #!!!

      # same as 'symbol = nil; remove_instance_variable(symbol)
      # untested...
      def rstore_remove_instance_variable symbol
	send(symbol.to_s + '=', nil)
	@model_value.send(:remove_instance_variable, symbol)
      end

      def inspect
        "#{self.class}[OID:#@rstore_oid]" # STACKOVERFLOW: {RStoreNode::rstore_value2hash(self, @rstore_rstore).inspect}"
      end
      
      def rstore_rstore
#         tag "#{self}::rstore_rstore, parent=#@model_parent"
        @model_parent.rstore_rstore
      end

      # override Model::length here
      def length
        @model_value.length
      end

      def == other
#         tag "#{self} == #{other}, #@model_value == other -> #{@model_value == other}"
        super || @model_value == other
      end

      attr_accessor :rstore_oid

      # called internally before marshalling-out the result.
      # the reverse of rstore_hash2value
      def self.rstore_value2hash value, rstore
#         tag "rstore_value2hash(#{value.pretty_inspect})"
        if rstore_atom?(value)
#           tag "value is atomic"
          value
        else
          case value
          when Array then self.rstore_array2hash value, rstore
          when Hash then self.rstore_hash2hash value, rstore
          else
#             tag "restoring instance of class #{value.class}"
            ivs = value.instance_variables
            if ivs.all? { |iv| rstore_atom?(value.instance_variable_get(iv)) }
#               tag "ALL ATOMIC attributes, easy peasy"
              return value
            end
            v = value.clone
            ivs.each do |iv|
#               tag "h2v #{value}: handling ivar #{iv}"
              val = value.instance_variable_get(iv)
              if rstore_atom?(val)
                v.instance_variable_set(iv, val)
              elsif OidRef === val
                v.send(:remove_instance_variable, iv)
                v.instance_variable_set((iv.to_s + RSTORE_ATTR_SUFFIX), val.oid)
              elsif RStoreNode === val
                v.send(:remove_instance_variable, iv)
                v.instance_variable_set((iv.to_s + RSTORE_ATTR_SUFFIX), val.rstore_oid)
              else
#                tag "rstore_value2hash, complex value #{val}"
                unless oid = rstore.objectspace[id = val.object_id]
                  oid = rstore.rstore_gen_oid(val)
#                  tag "rstore_value2hash generated oid '#{oid}' for ivar #{iv}"
                  rstore.rstore_assign_i oid, val
                end
                v.send(:remove_instance_variable, iv)
                v.instance_variable_set((iv.to_s + RSTORE_ATTR_SUFFIX), oid)
#                 tag "assigned oid to '#{iv.to_s + RSTORE_ATTR_SUFFIX}'"
              end
            end # each
#             tag "returning 'flat' item #{v.inspect}"
            v
          end
        end
      end

      # where 'hash' is actually what was unmarshalled. We need a little fixup to
      # do.
      def self.rstore_hash2value hash, rstore = nil
#        tag "unmarshalled hash of class #{hash.class} -> RStoreNode"
        case hash
        when OidRefs
#          tag "OidRefs"
          hash.map { |oid| OidRef.new(oid) }
        when Hash
#          tag "real Hash 2 value, keys=#{hash.keys}"
          return hash if hash.keys.none? { |key| key[-RSTORE_ATTR_SUFFIX_LEN..-1] == RSTORE_ATTR_SUFFIX }
          h = {}
          hash.each do |k, v2|
            if k[-RSTORE_ATTR_SUFFIX_LEN..-1] == RSTORE_ATTR_SUFFIX
              h[k[0...-RSTORE_ATTR_SUFFIX_LEN].to_sym] = OidRef.new(v2)
            else
              h[k] = v2
            end
          end
#	  tag "hash2value->#{h.pretty_inspect}"
          h
        when Array
#          tag "Array: nothing to improve -> #{hash.pretty_inspect}"
          hash
        else
#           tag "restoring instance of class #{hash.class}"
          ivs = hash.instance_variables
          # BEWARE: only atoms can ever be part!
#           if ivs.all? { |iv| rstore_atom?(hash.instance_variable_get(iv)) }
#             tag "ALL ATOMIC attributes, easy peasy"
#             return hash
#           end
          if ivs.none? { |iv| iv[-RSTORE_ATTR_SUFFIX_LEN..-1] == RSTORE_ATTR_SUFFIX }
#             tag "no iv matched /rstore_oid^/, easy peasy"
            return hash 
          end
#           v = hash.clone          # propably not really required
          ivs.each do |iv|
            if iv[-RSTORE_ATTR_SUFFIX_LEN..-1] == RSTORE_ATTR_SUFFIX
              val = hash.instance_variable_get(iv)
#               tag "swapping OidRef #{val}"
              hash.instance_variable_set(iv[0...-RSTORE_ATTR_SUFFIX_LEN], OidRef.new(val))
              hash.send(:remove_instance_variable, iv)
#             else
#               v.instance_variable_set(iv, val)
            end
          end
#           tag "Returning instance #{hash.pretty_inspect}"
          hash
        end
      end # rstore_hash2value

      # THE UNSPEAKABLE!!!
      def class
        @model_value.class
      end

      def instance_of? klass
        if @model_value.instance_of? klass
          true
        else
          super
        end
      end

      # override
      def model_row numeric_key
        case rv = model_row_i(numeric_key)
        when OidRef
	  if v = rstore_rstore.revspace[oid = rv.oid]
	    rv = v
	  else
	    rv = rstore_rstore.rstore_oid2value(oid)
#	    tag "and return a new wrapper!"
	    rv = RStoreNode.new(self, numeric_key, rv, oid)
	    rstore_rstore.revspace[oid] = rv
	  end
          # Now remove the OidRef
	  @model_value[numeric_key] = rv
        end
	rv
      end

      #override
      def model_getter? name
        case name
        when :self, Proc then true
        when Symbol, String then (!@model_value.respond_to?(:has_key?) || @model_value.has_key?(name))
        else true
        end
      end

      # override. To apply the getter, this method must be used.
      def model_apply_getter name
#         tag "model_apply_getter(#{name.inspect}), value=#@model_value"
        case name
#        when :self             We cannot support showing the inner structure. EVER!!!
 #         Array === @model_value || Hash === @model_value ? self : @model_value
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
#	      tag "TypeError, for [#{name.inspect}].model_value is #{@model_value.inspect}"
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
        #tag "model_apply_setter(#{name.inspect}, #{value}, sender = #{sender})"
  #         name = name.to_s
  #         name = name[0...-1] if name[-1] == '?'
        if Array === name
          sub = name[0...-1].inject(self) { |v, nm| v && v.model_apply_getter(nm) } and
            sub.model_apply_setter(name[-1], value, sender)
        else
          model_pickup_tran(sender) do |tran|
            if tran.aborted?
              model_assign(name, value)
            else
              tran.debug_track! if more_args && more_args[:debug_track]
              prev = calc_prev(name)
              model_assign(name, value)
  #             tag "ADDING PROPCHANGE"
              tran.addPropertyChange(self, name, prev)
            end
          end
        end
      end

      # important override
      def respond_to? symbol
        # only the getters are really covered here.
        @model_value.respond_to?(symbol) || 
	  Hash === @model_value && @model_value[symbol] || super
      end

      # this method is used to set the proper row, if 'value' is connected to it.
      # Now the problem is that Hashes and Arrays can connect to their index or 
      # their value.
      #
      # IMPORTANT saying 'key_connector:id' is not the same as leaving it 
      # the default (also :id)
      # Because this switches on locating the value by key
      #
      def model_value2index value, view
#	tag "#{self}::model_value2index(#{value}, view:#{view})"
        return 0 if value.nil?
        key_connector = view.key_connector
        key = model_value2key(value, view) or
          key ||= value if key_connector # if key-lookup is enforced,
#         tag "model_value2index, key_connector=#{key_connector}, key = #{key.inspect}, value was #{(value.respond_to?(:value) ? value.value : value).inspect}"
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

  end # class RStoreNode

  # RStore is the toplevel node. It is simply an extended RStoreNode and
  # hence can wrap around any object or hash or array.
  # RStore has extended caching tables so consume quite a lot of memory
  class RStore < RStoreNode
      ROOT_OID = '0'
      # RStore::Node == RStoreNode, for some reason
      Node = RStoreNode
    private # RStore method
      # Create a new rstore.
      # The extension of dbname is important.
      # If +dbname+ is nil, a nil-store (non persistent) is created
      # If +init_value+ is set, it is used as initial value, provided
      # +dbname+ was nil. Otherwise ignored
      def initialize dbname, init_value = nil
        super(nil, nil, nil, ROOT_OID)
        # hash from object_id to oid
        @objectspace = {}
	# hash from oid to instance (should be an RStoreNode)
	@revspace = {}
        # transaction in progress:
        @in_tran = nil
        # backend:
        @rstore_db = 
          case dbname
          when nil 
            require_relative '../rstores/nil'
            RStoreBackend::Nil.new
          when /\.kch$/ 
            require_relative '../rstores/kyoto'
            RStoreBackend::KyotoCabinet.new(dbname)
          when /\.g?dbm?$/
            require_relative '../rstores/gdbm'
#             tag "open GDBM #{dbname}"
            RStoreBackend::GDBM.new(dbname)
          else  
            raise "Don't know how to handle database '#{dbname}'"
          end
        raise 'blech' if @rstore_db.closed?
        if rstore_root = @rstore_db[ROOT_OID]
#           tag "rstore_db[ROOT_OID] = #{rstore_root.inspect}"
	  if !dbname && init_value
	    clear init_value
	  else
	    t = Marshal::load(rstore_root)
	    if t.nil?
	      STDERR.print "OK, attempt to fix CORRUPTED database!!! CLEANED\n"
	      clear
	    else
  #             tag "Loaded marshal-ed raw value #{t.pretty_inspect}, calling rstore_hash2value"
	      @model_value = RStoreNode::rstore_hash2value(t, self)
  #             tag "Loaded marshal-ed value #{@model_value.pretty_inspect}"
	    end
	  end
        else
          clear(dbname ? nil : init_value)
        end
        if block_given?
          begin
            yield self
          ensure
            close
          end
        end
      end

      # traverse val adding all oids to the '@marked' hash
      def rstore_mark val
#        tag "Marking reached node #{val.inspect}"
        case val
        when OidRef 
#          tag "OidRef, marked = #{@marked[val.oid]}"
          return if @marked[val.oid]
#          tag "MARKED: #{val.oid}!"
          @marked[val.oid] = true
          rstore_mark(rstore_oid2value(val.oid))
        when Array
#          tag "Array with #{val.length} values"
          val.each { |v| rstore_mark(v) unless Node::rstore_atom?(v) }
        when Hash
#          tag "Hash with #{val.length} values"
          val.each_value { |v| rstore_mark(v) unless Node::rstore_atom?(v) }
        else
          ivs = val.instance_variables
#          tag "Instance with #{ivs.length} attributes"
          ivs.each do |iv|
            v = val.instance_variable_get(iv)
#            tag "ivar: #{v.inspect}"
            rstore_mark(v) unless Node::rstore_atom?(v)
          end
        end
#        tag "return from mark"
      end
      
    public # RStore methods

      def clear init_value = nil
        @rstore_db.clear
	@in_tran = false
	@objectspace = {}
	@revspace = {}
	if init_value
	  model_pickup_tran do |tran|
	    @model_value = init_value
	    RStoreNode::rstore_wrap(nil, @model_value, self, self)
	  end
	else
	  @model_value = {}
	end
        @rstore_db[ROOT_OID] = Marshal::dump(RStoreNode::rstore_value2hash(@model_value, self))
      end
      
        # it must be public
      def rstore_rstore
#         tag "RStore::rstore_rstore"
        self
      end

      attr :objectspace, :revspace

      # this is important since it connects us to the controltree
      attr_accessor :parent

      def tran?
        @in_tran
      end

      def rstore_gen_oid val 
        oid = @rstore_db['next_rstore_oid'] || 'A'
#         tag "rstore_gen_oid, oid = #{oid.inspect}"
        # to the uniformed: next-> A...Z.AA...AZ.BA...BZ etc etc 
        @rstore_db['next_rstore_oid'] = oid.next
	@objectspace[val.object_id] = oid
	@revspace[oid] = val 
        oid
      end

      def close
#         tag "closing the rstore"
        @rstore_db.close
	@objectspace = @revspace = nil
	@in_tran = false
      end

      # override. It is important to realize that assignments causing 'inter'
      # actually update the backend. So we must start a backend transaction.
      def model_begin_work
#         tag ">>> model_begin_work"
        raise ProtocolError, 'transaction already started' if @in_tran
        @rstore_db.begin_transaction
        @in_tran = true
      end

      def model_commit_work altered_owners
        raise ProtocolError, 'no transaction to commit' unless @in_tran
#        tag ">>> model_commit_work, altered_owners = #{altered_owners.inspect}"
        altered_owners.each do |object_id, node|
          raise 'aaargh' unless RStoreNode === node
          raise 'aargh' unless oid = node.rstore_oid
          rstore_assign_oid oid, node.model_value
        end
        @rstore_db.end_transaction(true)
        @in_tran = false
      end

      def model_abort_work
#         tag ">>> model_abort_work"
        raise ProtocolError, 'no transaction to abort' unless @in_tran
        @rstore_db.end_transaction(false)
        @in_tran = false
      end

      def rstore_assign_i oid, value 
#         tag "rstore_assign_i[#{oid}] := marshal(#{value})" #, caller=#{caller.join"
        raise 'oh no' if value.nil?
        raise 'WTF' if RStoreNode === value
        @rstore_db[oid] = Marshal::dump(value)
      end
        
      def rstore_assign_oid oid, value
        raise 'BOGO call: trying to store a wrapper??' if RStoreNode === value
        raise 'Attempt to update outside transaction' unless @in_tran
        raise 'wtf' if oid =~ /^rstore/
#         tag "Storing node in rstore DB: oid=#{oid} => #{value.inspect}"
        rstore_assign_i oid, RStoreNode::rstore_value2hash(value, self)
      end

      def rstore_oid2value oid
        t = Marshal::restore(@rstore_db[oid])
#         tag "raw rstore node unmarshalled[#{oid}]->#{t.pretty_inspect}"
        RStoreNode::rstore_hash2value(t, self)
      end
      
      #override
      def model_has_own_storage?
        true
      end

      # internal stuff. How many keys are on disk. Some may be dead
      def rstore_db_length
        @rstore_db.length
      end
     
      # for debugging purposes
      def rstore_db_inspect
        @rstore_db.each_pair.to_a.pretty_inspect
      end
      
      def garbage_collect
#        tag "garbage_collect"
        @marked = { ROOT_OID=>true }
#        tag "marking"
        rstore_mark(rstore_oid2value(ROOT_OID))
#        tag "sweep, marked nodes= #{@marked.keys.inspect}"
        sweep = []
        @rstore_db.each_key { |key| sweep << key unless @marked[key] }
#        tag "actually delete them, sweep=#{sweep.inspect}"
        sweep.each { |key| @rstore_db.delete(key) }
        @marked = nil
      end
      
      alias :compact :garbage_collect
        # no event, no transaction.
#         @model_value.compact!   no such method exists
#         garbage_collect
#       end

  end # class RStore

end # module Reform

__END__

Lazyness?
==============

when a value is assigned into the rstore we expand all subnodes. But this could be delayed
until Marshal is called.

But it may create new values which should be added to the transaction, or they will never be saved.

However, what is saved to disk is not what is literally present.  Any RStoreNode must be
collapsed. Even more, for hash or object keys we can alter the key!

So   { a: RStoreNode (oid: x....), b: RStoreNode (oid: y, ...) }
can be saved as { a_rstore_oid: x, b_rstore_oid: y } !
same for objects.

And when loaded these can be left as is!! Until they are read.
That's why rstore_inter should probably take care of such keys by letting them stay
as is. An Oid is obviously just a fixnum





