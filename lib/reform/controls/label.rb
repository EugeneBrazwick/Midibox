
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

    public
    def text value = nil
      return @qtc.text unless value
#       tag "Assigning labeltext '#{value}'"
      @qtc.text = value
    end
  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::Label, Label

end