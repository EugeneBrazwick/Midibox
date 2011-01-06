module Reform

  require 'reform/control'

=begin    # it may even be a very good idea to implement to 'enabler' and 'disabler' the very same way!
# they are now kind of polluting the updateModel method.

  windowTitle { connector { |m| m.myTitle} }

  new DynamicAttribute self, :windowTitle, quicky, block
=end
  class DynamicAttribute < Control

    private # DynamicAttribute methods

      def initialize parent, propertyname, klass, quickyhash = nil, &block
#         tag "DA.new: par:#{parent}, name: :#{propertyname}, quickyhash=#{quickyhash.inspect}, block=#{block}"
        super(parent)
        @propertyname, @klass = propertyname, klass
        if quickyhash
          if Hash === quickyhash
            setup(quickyhash, &block)
          else
            applyModel quickyhash
          end
        elsif block
          setup(quickyhash, &block)
        end
#         tag "setting the default in 'value'"
        setProperty('value', value2variant(:default))
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
        SequentialAnimation.new(self, Qt::SequentialAnimationGroup.new(self)).setup(quickyhash, &block)
      end

      def animation quickyhash = nil, &block
        require_relative 'animations/attributeanimation'
#             tag "Creating Qt::Variant of value"
        setProperty('value', value2variant(:default))
#             tag ("calling Animation.new")
        AttributeAnimation.new(self, Qt::PropertyAnimation.new(self)).setup(quickyhash, &block)
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
#               tag "applyModel(#{val.inspect})"
          applyModel val
#             else
#               tag "unhandled .... #{self}.event(#{e})"
        end
#             super  not much use
      end

      def value2variant *value
        # Note: if 'c = Array' then 'Array === c' => false (!)
        # So 'case @klass' will not work.
#         tag "#{value.inspect}, klass= #@klass"
        case @klass.name
        when 'Qt::Color', 'Qt::Brush', 'Qt::Pen'
          color = Graphical.color(*value)
#               tag "Qt::Variant.new(#{color})"
          Qt::Variant::fromValue(color)
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
        else
          raise Error, tr("Not implemented: animation for property '#@propertyname', klass=#@klass")
        end
      end

      # called when Qt::DynamicPropertyChangeEvent is received
      def applyModel data, model = nil
#         tag "DynamicPropertyChangeEvent -> #{self}::applyModel #{parent}.#@propertyname := #{data.inspect}"
        parent.send(@propertyname.to_s + '=', data)
      end

      # the result is a symbol
      attr :propertyname, :animprop

      alias :propertyName :propertyname

#           attr_accessor  :value

#           properties 'value'

      def value
        property('value').value # .tap{|t| tag "value -> #{t.inspect}"}
      end

      def dynamicParent
        self
      end

  end # class DynamicAttribute

end # module Reform