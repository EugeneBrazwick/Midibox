
module Reform

  class Menu < Control
    include ActionContext

    private

      def initialize parent, qtc
        super
        @fs = nil
      end

      def filesystem value
        @fs = value
      end

      define_simple_setter :title
      alias :text :title

      # 'label' is a tricky name as it is also a widget.
      # But it seems an OK name for things that are in fact labels
      alias :label :title

# IMPORTANT $qApp.quit bypasses closing of forms.
      def fileQuit
        action {
          name :fileQuitAction
          label tr('E&xit')
          shortcut :quit
          statustip tr('Quit the application')
          whenTriggered { $qApp.quit if whenCanceled }
        }
      end

      alias :quit :fileQuit
      alias :quiter :fileQuit

      def aboutQt
        action {
          label tr('About &Qt')
          whenTriggered { $qApp.aboutQt }
        }
      end

# it would be possible to make a class for each and put them in 'actions/'
# but that seems a waste of classes
      # you must supply the file-model, or set it first using 'filesystem'
      def fileOpen fs = @fs
        action {
          name :fileOpenAction
          title tr('&Open...')
          shortcut :open
          statustip fs.open_caption
          whenClicked { fs.fileOpen(self) }
        }
      end

      def fileNew fs = @fs
        action {
          name :fileNewAction
          title tr('&New')
          shortcut :new
          statustip fs.new_caption
          whenClicked { fs.fileNew }  # fileNew never interacts
        }
      end

      def fileSave fs = @fs
        action {
          name :fileSaveAction
          title tr('&Save')
          shortcut :save
          statustip fs.save_caption
          whenClicked { fs.fileSave(self) }
        }
      end

      def fileSaveAs fs = @fs
        action {
          name :fileSaveAsAction
          title tr('&Save As...')
          shortcut :saveas
          statustip fs.saveas_caption
          whenClicked { fs.fileSaveAs(self) }
        }
      end

      def editUndo
        @qtc.addAction($undo.createUndoAction(@qtc))
      end

      def editRedo
        @qtc.addAction($undo.createRedoAction(@qtc))
      end

    public

      def postSetup
        STDERR.puts("warning: menu has no title!") unless @qtc.title
        super
      end

#     def self.contextsToUse
#       MenuContext
#     end

# #     def menu?
#       true
#     end

    def addTo parent, hash, &block
      parent.addMenu self, hash, &block
    end

    # ignore the parent
    def self.new_qt_implementor qt_implementor_class, parent, qt_parent
      qt_implementor_class.new
    end

    # Frame compat
    def registerName aName, aControl
      containing_form.registerName(aName, aControl)
    end

    def self.parent_qtc control, qtc
    end

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::Menu, Menu

end