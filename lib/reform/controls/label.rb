
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

  # slightly problematic and only for simplistic settings:
    AlignmentMap = { left: Qt::AlignLeft, right: Qt::AlignRight,
                     hcenter: Qt::AlignHCenter, justify: Qt::AlignJustify,
                     top: Qt::AlignTop, bottom: Qt::AlignBottom,
                     vcenter: Qt::AlignVCenter,
                     center: Qt::AlignHCenter | Qt::AlignVCenter
                     # topleft, ... etc. then we have :absolute etc.....
                    }
    def alignment value = nil
      return @qtc.alignment if value.nil?
      Symbol === value and value = AlignmentMap[value] || Qt::AlignLeft
      @qtc.alignment = value
    end

    public

    def pixmap= val
      @qtc.pixmap = val
    end

    def text value = nil
      return @qtc.text unless value
#       tag "Assigning labeltext '#{value}'"
      @qtc.text = value
    end

    def pixmap
      @qtc.pixmap
    end
  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::Label, Label

end