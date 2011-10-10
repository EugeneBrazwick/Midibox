module Reform

#  require 'reform/control'             control is  already in autoload. Require 'reform/app' instead!

=begin    # it may even be a very good idea to implement to 'enabler' and 'disabler' the very same way!
# they are now kind of polluting the updateModel method.

  windowTitle { connector { |m| m.myTitle} }

  new DynamicAttribute self, :windowTitle, quicky, block
=end
  class DynamicAttribute < Control

    private # DynamicAttribute methods

      def initialize parent, propertyname, klass, quickyhash = nil, &block
#         tag "CALLING super WITHOUT hash/block!!!!!!!!!!!!!!"
        # BEWARE: ruby passes on any passed 'block' even if I leave it out here:
        super(parent) {}
#         @qtc = klass.new STUPID IDEA klass can be Float or Integer.
#         tag "DA.new: par:#{parent}, name: :#{propertyname}, quickyhash=#{quickyhash.inspect}, block=#{block}, klass=#{klass}, qtc=#@qtc"
        raise 'wtf' unless propertyname && klass
	@options = nil
        #setupQtc               INSANE. there is NO qtc anywhere!!!
        @propertyname, @klass = propertyname, klass
        setProperty('value', value2variant(:default))  # DynamicAttribute is a Qt::Object after all
        # setProperty must come BEFORE setup, as the setup may alter it.
        if quickyhash
          if Hash === quickyhash
#             tag "setup quickyhash"
            setup(quickyhash, &block)
          else
#             tag "assume that quickyhash is a model"
            applyModel quickyhash
          end
        elsif block
          setup(nil, &block)
        end
#         tag "setting the default in 'value'"
#         tag "OK"
      end

      def apply_dynamic_getter name
#        tag "apply_dynamic_getter(#{name}), send to #{value}"
        value.send(name)
      end

      def apply_dynamic_setter(assigner, *args)
#         getter = name.to_s[0...-1]
#         tag "#{self}::accepting #{assigner} (#{args.inspect}), prop=#@klass::#@propertyname from #{parent}"
        propval = value
#         tag "SEND #{propval}::#{assigner} #{args.inspect}"
        propval.send(assigner, *args)
        setProperty('value', value2variant(propval))
#        tag "SEND #{parent}::#@propertyname := #{propval}"
        parent.send(@propertyname.to_s + '=', propval)
      end

      def through_state states2values
        form = containing_form
        setProperty('value', value2variant(:default))
        states2values.each do |state, value|
          form[state].qtc.assignProperty(self, 'value', value2variant(value))
        end
      end

      def sequence quickyhash = nil, &block
        require_relative 'animations/sequentialanimation'
        setProperty('value', value2variant(:default))
        SequentialAnimation.new(self, QSequentialAnimationGroup.new(self)).setup(quickyhash, &block)
      end

      def animation quickyhash = nil, &block
#         tag "animation, property = #{parent}.#@propertyname, klass=#@klass" #, caller=#{caller.join("\n")}"
        require_relative 'animations/attributeanimation'
#             tag "Creating Qt::Variant of value"
        setProperty('value', value2variant(:default))
#         tag ("calling Animation.new")
        AttributeAnimation.new(self, QPropertyAnimation.new(self)).setup(quickyhash, &block)
      end

      # macro to define single arg 'component'. For example Color may have 'red', and Point has 'x' and 'y'.
      def self.def_acceptors *names
        names.each do |name|
          assigner = (name.to_s + '=').to_sym
          define_method assigner do |v|
            apply_dynamic_setter(assigner, v)
          end
        end
      end

    public # DynamicAttribute methods

      # override
      def event e
#             tag "#{self}.event(#{e})"
        case e
        when Qt::DynamicPropertyChangeEvent
          # we may expect the value to be 'value'
          raise "unexpected property '#{e.propertyName}'" unless e.propertyName == 'value'
          val = property('value').value
#           tag "applyModel(#{val.inspect})"
          applyModel val
#             else
#               tag "unhandled .... #{self}.event(#{e})"
        end
#             super  not much use
      end

      def value2variant *value
        # Note: if 'c = Array' then 'Array === c' => false (!)
        # So 'case @klass' will not work.
#         tag "#{self}::value2variant, prop:#{parent}::#@propertyname, val=#{value.inspect}, klass= #@klass"
        case @klass.name
        when 'Qt::Color', 'Qt::Brush', 'Qt::Pen'
          color = Graphical::make_color(*value)
#               tag "Qt::Variant.new(#{color})"
          Qt::Variant::fromValue(color)
        when 'Qt::PointF'
#           tag "value to Qt::PointF, value: #{value.inspect}"
          Qt::Variant::fromValue(case value[0]
          when :default then Qt::PointF.new
          when Qt::PointF then value[0]
          else Qt::PointF.new(*value)
          end)
        when 'Qt::SizeF'
          Qt::Variant::fromValue(case value[0]
          when :default then Qt::SizeF.new
          when Qt::SizeF then value[0]
          else Qt::SizeF.new(*value)
          end)
        when 'Qt::Rect'
          Qt::Variant::fromValue(case value[0]
          when :default then Qt::Rect.new
          when Qt::Rect then value[0]
          else Qt::Rect.new(*value) #.tap{|r| tag "creating value(#{r.inspect})"}
          end)
        when 'Qt::RectF'
          Qt::Variant::fromValue(case value[0]
          when :default then Qt::RectF.new
          when Qt::RectF then value[0]
          else Qt::RectF.new(*value) #.tap{|r| tag "creating value(#{r.inspect})"}
          end)
        when 'Float'
#               debug Qt::DebugLevel::High do
          f = value[0] == :default ? 0.0 : value[0]
#                 tag "value2variant, value = #{value.inspect}, f = #{f.inspect}, #{f.class}"
          Qt::Variant.new(f)
#               end
        when 'Integer'
          Qt::Variant.new(value[0] == :default ? 0 : value[0])
        when 'TrueClass'
          Qt::Variant.new(value[0] == :default || value[0])
        when 'FalseClass'
          Qt::Variant.new(value[0] == :default ? false : value[0])
        when 'String'
          Qt::Variant.new(value[0] == :default ? '' : value[0])
        else
          raise Error, tr("Not implemented: animation for property '#@propertyname', klass=#@klass")
        end
      end

      # called when Qt::DynamicPropertyChangeEvent is received
      def applyModel data, model = nil
#         tag "DynamicPropertyChangeEvent -> #{self}::applyModel #{parent}.#@propertyname := #{data.inspect}"
#         tag "??? Sending #{@propertyname.to_s + '='}(#{data.inspect}) to #{parent}"
        n = (@propertyname.to_s + '=').to_sym
#         tag "#{parent}.respond_to?(#{n}) == #{parent.respond_to?(n)}"
        if parent.respond_to?(n)
#           tag "#{n} OK!"
          parent.send(n, data)
        else
          parent.apply_dynamic_setter(n, data)
        end
#         tag "OK!"
      end

      # the result is a symbol
      attr :propertyname, :animprop
      attr_writer :options

      alias :propertyName :propertyname

#           attr_accessor  :value

#           properties 'value'

      def value
        property('value').value #.tap{|t| tag "value -> #{t.inspect}"}
      end

      def dynamicParent
        self
      end

  end # class DynamicAttribute

end # module Reform
