
# $VERBOSE = true

# TODO: fully persistent version of structure.rb
# And automatically persistent.

=begin

  rstores cannot be initialized with data.
  A special program should do this.
  'new' will connect to the rstore and hence a completely filled instance
  is always immediately at your service.

  rstore will use yaml files on disk and some clever cutting algo to keep
  things fast.
  rstore v1 will not be transaction save.  The data may get corrupted if
  the application crashes or in all other cases where a transaction is
  partly executed.


  GARBAGE COLLECTION
  ==================
  the database has no idea about which nodes can be reached from the root!
  Therefor it must be periodically scanned and cleaned using a true GC.
  NOT IMPLEMENTED YET: and hence it will grow and grow. FIXME

=============================
  MAD SCIENTIST ALERT!!!!
=============================
  for the art of programming the author made sure that RStoreNode cannot be
  easily distinguished from what it is wrapping...
  See the specs. It seems to work even though Module#=== and RStoreNode#class
  are now hacked and slighlty unreliable.

=end

class Module
  alias :old_eqeqeq :'==='

  def === obj
    if obj.instance_of?(RStoreNode) && self === obj.model_value
      true
    else
      old_eqeqeq(obj)
    end
  end
end

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

      def initialize parent, key, value, oid
        raise 'BOGO' if !(nil == key || Symbol === key || Integer === key && key < 10_000_000)
        raise 'arg' if Class === parent
        @model_parent, @model_key, @model_value = parent, key, value
#         tag "#{self}.new, parent=#{@model_parent}, key=#{key.inspect}, value=#{value}, oid=#{oid}"
#         raise 'BOGO' unless value             Sometimes assigned later on
        @rstore_oid = oid
      end

      def model_assign key, value, method_symbol = nil
#         tag "model_assign[#{key}] := #{value.inspect}"
        raise 'WTF' if value.nil?
        raise '?' if RStoreNode::rstore_atom?(@model_value)
        val = RStoreNode::rstore_inter(key, value, self, rstore_rstore)
        case @model_value
        when Array, Hash
          @model_value[key] = val
        else
          @model_value.send((key.to_s + '=').to_sym, val)
        end
#         tag "model_value is now #{@model_value.inspect}"
      end

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
      def self.rstore_inter key, value, parent, rstore
        if rstore_atom?(value)
          value
        else
          raise 'what?' if RStoreNode === value
          ospace = rstore.objectspace
          unless oid = ospace[id = value.object_id]
            ospace[id] = oid = rstore.rstore_gen_oid
            rstore[oid] = value
          end
          case value
          when Hash
            value.each do |k, v|
              value[k] = rstore_inter(k, v, parent, rstore)
            end
            RStoreNode.new(parent, key, value, oid)
          when Array
            value.each_with_index do |v, k|
              value[k] = rstore_inter(k, v, parent, rstore)
            end
            RStoreNode.new(parent, key, value, oid)
          else
            if value.respond_to?(:model?) && value.model?
              STDERR.print "kind of mounted model '#{value}' detected, not stored!!!"
              value.model_parent = parent
              value.model_key = key
              value
            else
              RStoreNode.new(parent, key, value, oid)
            end
          end
        end
      end

      # IMPORTANT: copie from structure.rb
      # We could reimplement structure as an rstore with a particular backend.
      # This includes handling of self[i] = val
      def handle_splices *args
#         tag "handle_splices #{self}::[]=#{args.inspect}"
        if args.length == 3  # x[3, 4] = ....
          # In cases of 'splice', if the last arg is an array, it is unpacked.
          # In cases of 'splice' arg2 is the nr of items deleted.
#               tag "splice operation"
          idx0, del_count, value = args
          value = [value] unless value.respond_to?(:length)
          key = args[0, 2]
#               oldvals = @model_value[*key]
        else 
#           tag "single key replacement,can be range"
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
#           tag "upd_count=#{upd_count},del_count=#{del_count},ins_count=#{ins_count}"
          # one by one
          for j in 0...upd_count
            oldval = @model_value[idx0]
            tran.addPropertyChange(self, idx0, oldval) unless tran.aborted?
#             tag "calling model_assign(#{idx}, #{value[j].inspect}"
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

    public # methods of RStoreNode

      attr :model_value
      attr :model_key # #!!!

      def rstore_rstore
#         tag "#{self}::rstore_rstore, parent=#@model_parent"
        @model_parent.rstore_rstore
      end

      def == other
#         tag "#{self} == #{other}, #@model_value == other -> #{@model_value == other}"
        super || @model_value == other
      end

      def method_missing symbol, *args, &block
#         tag "#{self}::METHOD_MISSING #{symbol.inspect}, current value = #{@model_value.inspect}"
        raise 'WTF' if @model_value.nil?
        case last_char = symbol.to_s[-1]
        when '='
          # assignments including splices  (ignored for now)
#           tag "args.length = #{args.length}"
          if symbol == :[]= #  So s.x[4] = ... something or s[4][:x] = ... or even s.y[2,4] = ....
            handle_splices *args
          else # key <> []
            return super if args.length > 1
            value = args[0]
  #           tag "value to assign = #{value.inspect}"
            key = symbol[0...-1].to_sym # !
            oldval = model_apply_getter(key)
            model_pickup_tran do |tran|
              model_assign(key, value, symbol)
  #             tag "addPropertyChange(#{self}, #{key.inspect}, oldval= #{oldval.inspect})"
              tran.addPropertyChange(self, key, oldval) unless tran.aborted?
  #             tag "COMMITTING!!!!!!!!!!!!!!!!!!"
            end
          end
        else
          # PARANOIA check for things that should definetely be methods
          raise "oh no! method #{symbol} should really exist!" if symbol[0, 7] == 'rstore_' || symbol[0, 6] == 'model_'  || symbol.to_s.to_i != 0 # how weird can it get?? #|| symbol == :key
          return self if symbol == :self && args.empty?
#           tag "Now use #@model_value to apply #{symbol} on"
          key = last_char == '?' ? symbol[0...-1].to_sym : symbol
          has_key = @model_value.respond_to?(:has_key?) && args.empty? && @model_value.has_key?(symbol)
          rv = if has_key then @model_value[key]
          elsif @model_value.respond_to?(symbol) then @model_value.send(symbol, *args, &block)
          else nil
          end
          if OidRef === rv
            rv = rstore_rstore[oid = rv.oid]
            # and return a new wrapper!
            rv = RStoreNode.new(self, symbol, rv, oid)
            # Now remove the OidRef
            if has_key
              @model_value[key] = rv
            else
              assigner = (symbol + '=').to_sym
              @model_value.send(assigner, rv) if @model_value.respond_to?(assigner)
            end
          end
          rv
        end
      end

      attr_accessor :rstore_oid

      # called internally before marshalling-out the result.
      # the reverse of rstore_hash2value
      def self.rstore_value2hash value, rstore
#         tag "rstore_value2hash(#{value.inspect})"
        if rstore_atom?(value)
          value
        else
          case value
          when Array
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
                  ospace = rstore.objectspace
                  unless oid = ospace[id = v.object_id]
                    ospace[id] = oid = rstore.rstore_gen_oid
                    rstore[oid] = v
                  end
                  a << OidRef.new(oid)
                end
              end
            end # each
#             tag "ready to marshal mixed node array: #{a.inspect}"
            a
          when Hash
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
                  ospace = rstore.objectspace
                  unless oid = ospace[id = v.object_id]
                    ospace[id] = oid = rstore.rstore_gen_oid
                    rstore[oid] = v
                  end
                  h[key] = oid
                end
              end
            end
            h
          else
            ivs = value.instance_variables
            if ivs.all? { |iv| rstore_atom?(value.instance_variable_get(iv)) }
#               tag "ALL ATOMIC attributes, easy peasy"
              return value
            end
            v = value.clone
            ivs.each do |iv|
              val = value.instance_variable_get(iv)
              if rstore_atom?(val)
                v.instance_variable_set(iv, val)
              elsif OidRef === v
                v.instance_variable_set((iv.to_s + RSTORE_ATTR_SUFFIX), v.oid)
              else
                unless oid = ospace[id = v.object_id]
                  ospace[id] = oid = rstore.rstore_gen_oid
                  rstore[oid] = v
                end
                v.instance_variable_set((iv.to_s + RSTORE_ATTR_SUFFIX), oid)
              end
            end
            v
          end
        end
      end

      # where 'hash' is actually what was unmarshalled. We need a little fixup to
      # do.
      def self.rstore_hash2value hash, rstore = nil
#         klass = hash.respond_to?(':[]') && hash[:rstore_class]
#         if klass
#           v = klass.new
#           raise 'niy: restoring class from hash'
#         else
        case hash
        when OidRefs
          raise 'niy: OidRefs'
        when Hash
          return hash if hash.keys.none? { |key| key[-RSTORE_ATTR_SUFFIX_LEN..-1] == RSTORE_ATTR_SUFFIX }
          h = {}
          hash.each do |k, v2|
            if k[-RSTORE_ATTR_SUFFIX_LEN..-1] == RSTORE_ATTR_SUFFIX
              h[k[0...-RSTORE_ATTR_SUFFIX_LEN].to_sym] = OidRef.new(v2)
            else
              h[k] = v2
            end
          end
          h
        when Array
          # nothing to improve
          hash
        else
#           raise "niy: restoring anything else: #{hash.inspect}"
          ivs = hash.instance_variables
          if ivs.all? { |iv| rstore_atom?(hash.instance_variable_get(iv)) }
#             tag "ALL ATOMIC attributes, easy peasy"
            return hash
          end
          v = hash.clone
          ivs.each do |iv|
            val = hash.instance_variable_get(iv)
            if[-RSTORE_ATTR_SUFFIX_LEN..-1] == RSTORE_ATTR_SUFFIX
              v.instance_variable_set(iv[0...-RSTORE_ATTR_SUFFIX_LEN], OidRef.new(val.oid))
            else
              v.instance_variable_set(iv, val)
            end
          end
          v
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
        else
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
      end

  end # class RStoreNode

  class RStore < RStoreNode
      ROOT_OID = '0'
    private # RStore methods
      def initialize dbname
        super(nil, nil, nil, ROOT_OID)
        # hash from object_id to oid
        @objectspace = {}
        @in_tran = nil
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
          t = Marshal::load(rstore_root)
          if t.nil?
            STDERR.print "OK, attempt to fix CORRUPTED database!!! CLEANED\n"
            @model_value = {}
            @rstore_db[ROOT_OID] = Marshal::dump(RStoreNode::rstore_value2hash(@model_value, self))
          else
            @model_value = RStoreNode::rstore_hash2value(t, self)
#             tag "Loaded marshal-ed value #{@model_value.inspect}"
          end
        else
          @model_value = {}
        end
        if block_given?
          begin
            yield self
          ensure
            close
          end
        end
      end

    public # RStore methods

        # it must be public
      def rstore_rstore
#         tag "RStore::rstore_rstore"
        self
      end

      attr :objectspace

      def tran?
        @in_tran
      end

      def rstore_gen_oid
        oid = @rstore_db['rstore_oid'] || 'A'
#         tag "rstore_gen_oid, oid = #{oid.inspect}"
        # to the uniformed: next-> A...Z.AA...AZ.BA...BZ etc etc 
        @rstore_db['rstore_oid'] = oid.next
      end

      def close
#         tag "closing the rstore"
        @rstore_db.close
      end

      def model_begin_work
#         tag ">>> model_begin_work"
        raise ProtocolError, 'transaction already started' if @in_tran
        @rstore_db.begin_transaction
        @in_tran = true
      end

      def model_commit_work altered_nodes
        raise ProtocolError, 'no transaction to commit' unless @in_tran
#         tag ">>> model_commit_work, altered_nodes = #{altered_nodes.keys.inspect}"
        altered_nodes.each do |object_id, node|
          raise 'aaargh' unless RStoreNode === node
          raise 'aargh' unless oid = node.rstore_oid
          self[oid] = node.model_value
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

      def []=(oid, value)
        raise 'BOGO call' if RStoreNode === value
        raise 'Attempt to update outside transaction' unless @in_tran
#         tag "Storing node in rstore DB: oid=#{oid} => #{value.inspect}"
        t = RStoreNode::rstore_value2hash(value, self)
#         tag "'hash' dumped is #{t.inspect}"
        raise 'oh no' if t.nil?
        @rstore_db[oid] = Marshal::dump(t)
      end

      def [](oid)
        t = Marshal::restore(@rstore_db[oid])
        RStoreNode::rstore_hash2value(t, self)
      end
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





