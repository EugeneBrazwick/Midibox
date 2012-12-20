
#  Copyright (c) 2010-2011 Eugene Brazwick

module Reform

  require_relative '../labeledwidget'

  class CheckBox < LabeledWidget
    private

      def initialize parent, qtc, connectit = true
	super(parent, qtc)
	if connectit
	  connect(@qtc, SIGNAL('clicked(bool)'), self) do |checked|
	    rfRescue do
	      if (cid = connector) && (mod = model)
		mod.model_apply_setter(cid, checked)
	      end
	    end
	  end
	  connect(@qtc, SIGNAL('toggled(bool)'), self) do |checked|
	    rfRescue do
	      if (cid = connector) && (mod = model)
		mod.model_apply_setter(cid, checked)
	      end
	    end
	  end
	end
      end # initialize

      define_simple_setter :text, :tristate, :checkState

      def text_connector connector = nil, &block
	@text_connector = block ? block : connector
      end

      def partiallyChecked
	checkState Qt::PartiallyChecked
      end

      def value
	true
      end

    public
      def whenClicked &block
	# note that clicked() is called from user interaction only (or click() calls)
	# but not when setChecked is used, or toggle() or setDown().
	if block
  #	tag "connecting clicked()"
	  connect(@qtc, SIGNAL('clicked(bool)'), self) do |checked|
	    # this does NOT overwrite the clicked() below!
	    rfCallBlockBack(checked, &block)
	  end
  #         @connected = true
	else
	  @qtc.clicked(@qtc.checked?)
	end
      end #whenClicked

      alias :whenChecked :whenClicked

      def whenToggled &block
	if block
  #	tag "connecting toggled()"
	  connect(@qtc, SIGNAL('toggled(bool)'), self) { |checked| rfCallBlockBack(checked, &block) }
	else
	  @qtc.toggled(@qtc.checked?)
	end
      end #whenToggled

      # override, also used for radiobutton
      def updateModel model, options = nil
  #       tag "@{self} updateModel #{aModel}, cid=#{connector}"
	if model
	  if (cid = connector) && model.model_getter?(cid)
	    @qtc.checked = model.model_apply_getter(cid) == value
	  end
	  if (tcid = text_connector) && model.model_getter?(tcid)
	    @qtc.text = model.model_apply_getter(tcid)
	  end
  #         tag "qtc.checked := model.#{cid}[?] == #{@qtc.checked}, model=#{@model}"
  #         if options && options[:initialize]
	else
	  @qtc.checked = false if connector
	end
	super
      end

  end # class CheckBox

  createInstantiator File.basename(__FILE__, '.rb'), Qt::CheckBox, CheckBox
end # Reform
