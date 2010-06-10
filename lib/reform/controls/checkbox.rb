
#  Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../labeledwidget'

  class CheckBox < LabeledWidget
    private

    def initialize parent, qtc, connectit = true
      super(parent, qtc)
      if connectit
        connect(@qtc, SIGNAL('clicked(bool)'), self) do |checked|
          model.apply_setter(cid, checked) if cid = connector && model = effectiveModel
        end
      end
    end # initialize

    define_simple_setter :text, :tristate, :checkState

    def partiallyChecked
      checkState Qt::PartiallyChecked
    end

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
        @qtc.clicked(@qtc.checked?)
      end
    end #whenClicked

    def whenToggled &block
      if block
        connect(@qtc, SIGNAL('toggled(bool)'), self) { |checked| rfCallBlockBack(checked, &block) }
      else
        @qtc.toggled(@qtc.checked?)
      end
    end #whenToggled


    # override
    def connectModel aModel, options = nil
#       tag "@{self} connectModel #{aModel}, cid=#{connector}"
      cid = connector or return
      if @model && @model.getter?(cid)
        @qtc.checked = @model.apply_getter(cid)
#         tag "qtc.checked := model.#{cid}[?] == #{@qtc.checked}, model=#{@model}"
#         if options && options[:initialize]
      else
        @qtc.checked = false
      end
      super
    end

  end # class CheckBox

  createInstantiator File.basename(__FILE__, '.rb'), Qt::CheckBox, CheckBox
end # Reform