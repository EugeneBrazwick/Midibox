
#  Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../labeledwidget'

  class CheckBox < LabeledWidget
    private

    define_simple_setter :text

    public
    # this will not call whenClicked
    def checked value = nil
      return @qtc.checked? if value.nil?
      @qtc.checked = value
    end

    def checked?
#       tag "#{name}::checked? -> #{@qtc.checked?}"
      @qtc.checked?
    end

    def whenClicked &block
      # note that clicked() is called from user interaction only (or click() calls)
      # but not when setChecked is used, or toggle() or setDown().
      if block
        connect(@qtc, SIGNAL('clicked(bool)'), self) do |checked|
          # this does NOT overwrite the clicked() below!
          rfCallBlockBack(checked, &block)
        end
#         @connected = true
      else
        @qtc.clicked
      end
    end #whenClicked

    # override
    def connectModel model, options = nil
#       tag "connectModel #{model}, cid=#{connector}"
      cid = connector or return
      if model && model.getter?(cid)
        @qtc.checked = model.apply_getter(cid)
#         tag "qtc.checked := model.#{cid}[?] == #{@qtc.checked}"
        if options && options[:initialize]
          cid = cid[0..-2] if cid[-1] == '?'
          connect(@qtc, SIGNAL('clicked(bool)'), self) do |checked|
            model.send(cid + '=', checked)
          end
        end
      else
        @qtc.checked = false
      end
      super
    end


  end # class CheckBox

  createInstantiator File.basename(__FILE__, '.rb'), Qt::CheckBox, CheckBox
end # Reform