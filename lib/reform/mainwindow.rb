
module Reform

  module QDialogWrapperContext
  public
    # override, call ifCanceled RForm callback and probably onClose as well.
    def closeEvent event
      if @_reform_hack.whenCanceled != false
        # this includes a nil return
        event.accept
        @_reform_hack.whenClosed
      else
        event.ignore
      end
    end

    attr_reader :_reform_hack # set by ReForm constructor
  end

  class QMainWindow < Qt::MainWindow
    include QDialogWrapperContext
  end

  class QDialog < Qt::Dialog
    include QDialogWrapperContext
  end

end # Reform