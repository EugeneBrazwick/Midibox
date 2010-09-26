
# Copyright (c) 2010 Eugene Brazwick

module Reform

  class Label < Widget
    private

    # the named control must then have the given name (a symbol normally)
    def buddy controlname
      # not good enough.... too late....
#       tag "Label.set buddy to #{controlname}"
      buddy = @containing_form[controlname]
      @qtc.buddy = buddy.qtc
      # the next thing will add the control to a formlayout (that should be around somewhere)
      buddy.labeltext self
    end

    define_simple_setter :scaledContents


    def alignment value = nil
      return @qtc.alignment if value.nil?
      Symbol === value and value = AlignmentMap[value] || Qt::AlignLeft
      @qtc.alignment = value
    end

    define_simple_setter :margin, :frameStyle

  public

    def_delegators :@qtc, :pixmap=, :pixmap, :margin=

    def text value = nil
      return @qtc.text unless value
#       tag "Assigning labeltext '#{value}'"

  # the following code should be made into a generic function   ???
  # But it does not work with models!
  # Can't we abuse DynamicAttribute for this?
  # DO NOT COPY IT !!!!!!!!!!!!
      if Hash === value
        value.each do |param, val|
          case param
          when :through_state
            form = containing_form
            val.each do |state, text|
              form[state].qtc.assignProperty(@qtc, 'text', Qt::Variant::from_value(text))
            end
          end
        end
      else
        @qtc.text = value
      end
    end

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::Label, Label

end