
# Copyright (c) 2010 Eugene Brazwick

module Reform

  module Model
    private
    # set the name of the model
    def name aName
#       tag "registerName in #{containing_form}"
      containing_form.registerName aName, self
    end

    module ClassMethods
      private
=begin rdoc
macro to assign the 'dynamic_writer' property to an attribute.
This is the same as attr_writer, but dynamicPropertyChanged will be called automatically.
This way of calling it is preferred.
What goes wrong?
You should make sure that assigning is the only way your property changes.
This seems easy, but...

    newval = myproperty
    newval[2,1] = '!'
    myproperty = newval

This goes terribly wrong!
The third assignment changes nothing since newval.equal?(myproperty).
It is simply the same object. As a result dynamicPropertyChanged is NOT called, since
the property did not change, as far as dynamic_writer is concerned.
Solution:
    newval = myprop.dup
    newval.mutilate
    myprop = newval

will work as expected
=end
      def dynamic_writer attrsym
        methname = (attrsym.to_s + '=').to_sym
        define_method methname do |value|
          attr = ('@' + attrsym.to_s).to_sym
          prev = instance_variable_defined?(attr) ? instance_variable_get(attr) : nil
#           tag "#{attr} := #{value}, prev = #{prev}"
          return if prev == value
          instance_variable_set(attr, value)
#           tag "calling dynamicPropertyChanged, value:='#{value}', ivg->#{instance_variable_get(attr)}"
          dynamicPropertyChanged attrsym
        end
#         public methname  EVIL
      end

      def dynamic_accessor *attrsyms
        # DO NOT USE 'for' here
        attrsyms.each do |attrsym|
          define_method attrsym do
#             tag "#{self}.#{attrsym}()"
            attr = ('@' + attrsym.to_s).to_sym
#             tag "calling instance_variable_get(#{attr})"
            instance_variable_defined?(attr) && instance_variable_get(attr)
          end
  #         public attrsym  EVIL
          dynamic_writer attrsym
        end
      end

      def dynamic_bool *attrsyms
        attrsyms.each do |attrsym|
          define_method "#{attrsym}?".to_sym do
            attr = ('@' + attrsym.to_s).to_sym
            instance_variable_defined?(attr) && instance_variable_get(attr)
          end
          dynamic_writer attrsym
        end
      end

      class << self
        alias :dynamic :attr
        alias :dynamic_reader :attr_reader
      end
    end # ClassMethods

    # override
    def self.included mod
#       tag "Included by #{mod}"
      mod.extend ClassMethods
    end

    public

    attr_accessor :containing_form

    # Control compatibility
    def postSetup
    end

    # Control compatibility
    def model?
      true
    end

    # Control compatibility
    def widget?
    end

    # observers are always ReForms, currently
    def addObserver_i observer
      (@observers ||= []) << observer
    end

    def removeObserver_i observer
      @observers.delete observer
    end

    # note that the :property option is not yet implemented
    def dynamicPropertyChanged name
#       tag "dynamicPropertyChanged #{name}" # may say boom, value = #{send(name)}"
      (@observers ||= nil) and for o in @observers
        o.connectModel self, property: name
      end
    end

=begin rdoc
    returns whether name may function as 'getter' on the model
    names like 'getX' are currently not supported.
    However, a proc can very well be a setter, where the object is
    passed as an argument.  This makes it possible to code the
    text or value to use in the gui, and not in the model.
=end
    def getter?(name)
#       tag "Does #{self.class}##{name} is a public method?"
      m = (public_method(name) rescue nil) or return
#       tag "m.arity = #{m.arity}"
      -1 <= m.arity && m.arity <= 0
    end

    # To apply the getter, this method must be used.
    def apply_getter name
#       tag "apply_getter #{name} to self == 'send'"
#       if respond_to?(name)
        send name
#       else
#         send(name.to_s + '?')
#       end
    end

=begin rdoc
    returns whether name may function as 'setter' on the model, if
    suffixed with an '=' char.
    names like 'setX' are currently not supported
=end
    def setter?(name)
      n = name.to_s
      n = n[0..-2] if n[-1] == '?'
      m = (public_method(n + '=') rescue nil) or return
      -2 <= m.arity && m.arity <= 1
    end

    # key -> any. When a model consists of an array, hash or list of other objects
    # and if to be used as a datasource in things like combobox, we must have a
    # key for each instance. If you use BasicObject somehow, this should be overriden.
    # If your keys are visible, an override would be convenient as well.
    def key
      __id__
#       raise ReformError, tr("to be usefull, #{self.class} should have an override for 'key'")
    end
  end

end
