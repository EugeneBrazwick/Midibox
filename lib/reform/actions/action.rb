
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require 'reform/abstractAction'
  require 'forwardable'

  class Action < AbstractAction
    include MenuContext
    extend Forwardable

    private

      def initialize parent, qtc
  #       tag "new #{self}, parent = #{parent}"
        super
        connect(@qtc, SIGNAL('triggered()')) do
          unless @qtc.checkable? # because toggled() WILL be called also
            rfRescue do
              if instance_variable_defined?(:@value) && (cid = connector) && (model = effectiveModel)
    #             tag "triggerered. apply_setter #{cid} on model #{model}, connector=#{connector} -> value = #@value"
                model.apply_setter cid, @value
              end
            end
          end
        end
        connect(@qtc, SIGNAL('toggled(bool)')) do |checked|
          rfRescue do
            if (cid = connector) && (model = effectiveModel)
              value = checked && instance_variable_defined?(:@value) ? @value : checked
  #             tag "toggled. apply_setter #{cid} on model #{model}, connector=#{connector} -> value = #{value}"
  #             tag "stack=#{caller.join("\n")}"
              model.apply_setter(cid, value)
            end
          end
        end
        connect(@qtc, SIGNAL('toggled(bool)')) do |checked|
          rfCallBlockBack(checked, &@whenToggled) if instance_variable_defined?(:@whenToggled)
        end
      end

      define_simple_setter :text
      define_setter FalseClass, :checkable
      define_setter String, :icon

      alias :label :text
      alias :title :text

      # sets 'enabled' to false
      def disabled
        @qtc.enabled = false
      end

      Sym2Shortcut = { addTab: Qt::KeySequence::AddTab,
                       back: Qt::KeySequence::Back,
                       bold: Qt::KeySequence::Bold,
                       close: Qt::KeySequence::Close,
                       copy: Qt::KeySequence::Copy,
                       cut: Qt::KeySequence::Cut,
                       delete: Qt::KeySequence::Delete,
                       deleteEndOfLine: Qt::KeySequence::DeleteEndOfLine,
                       deleteEndOfWord: Qt::KeySequence::DeleteEndOfWord,
                       deleteStartOfWord: Qt::KeySequence::DeleteStartOfWord,
                       find: Qt::KeySequence::Find,
                       findNext: Qt::KeySequence::FindNext,
                       findPrevious: Qt::KeySequence::FindPrevious,
                       forward: Qt::KeySequence::Forward,
                       helpContents: Qt::KeySequence::HelpContents,
                       insertLineSeparator: Qt::KeySequence::InsertLineSeparator,  # ie a new line
                       insertParagraphSeparator: Qt::KeySequence::InsertParagraphSeparator,
                       italic: Qt::KeySequence::Italic,
                       moveToEndOfBlock: Qt::KeySequence::MoveToEndOfBlock,
                       moveToEndOfDocument: Qt::KeySequence::MoveToEndOfDocument,
                       moveToEndOfLine: Qt::KeySequence::MoveToEndOfLine,
                       moveToNextChar: Qt::KeySequence::MoveToNextChar,
                       moveToNextLine: Qt::KeySequence::MoveToNextLine,
                       moveToNextPage: Qt::KeySequence::MoveToNextPage,
                       moveToNextWord: Qt::KeySequence::MoveToNextWord,
                       moveToPreviousChar: Qt::KeySequence::MoveToPreviousChar,
                       moveToPreviousLine: Qt::KeySequence::MoveToPreviousLine,
                       moveToPreviousPage: Qt::KeySequence::MoveToPreviousPage,
                       moveToPreviousWord: Qt::KeySequence::MoveToPreviousWord,
                       moveToStartOfBlock: Qt::KeySequence::MoveToStartOfBlock,
                       moveToStartOfDocument: Qt::KeySequence::MoveToStartOfDocument,
                       moveToStartOfLine: Qt::KeySequence::MoveToStartOfLine,
                       new: Qt::KeySequence::New,
                       nextChild: Qt::KeySequence::NextChild,
                       open: Qt::KeySequence::Open,
                       paste: Qt::KeySequence::Paste,
                       preferences: Qt::KeySequence::Preferences,
                       previousChild: Qt::KeySequence::PreviousChild,
                       print: Qt::KeySequence::Print,
                       quit: Qt::KeySequence::Quit,
                       redo: Qt::KeySequence::Redo,
                       refresh: Qt::KeySequence::Refresh,
                       replace: Qt::KeySequence::Replace,
                       save: Qt::KeySequence::Save,
                       saveAs: Qt::KeySequence::SaveAs,
                       selectAll: Qt::KeySequence::SelectAll,
                       selectEndOfBlock: Qt::KeySequence::SelectEndOfBlock,
                       selectEndOfDocument: Qt::KeySequence::SelectEndOfDocument,
                       selectEndOfLine: Qt::KeySequence::SelectEndOfLine,
                       selectNextChar: Qt::KeySequence::SelectNextChar,
                       selectNextLine: Qt::KeySequence::SelectNextLine,
                       selectNextPage: Qt::KeySequence::SelectNextPage,
                       selectNextWord: Qt::KeySequence::SelectNextWord,
                       selectPreviousChar: Qt::KeySequence::SelectPreviousChar,
                       selectPreviousLine: Qt::KeySequence::SelectPreviousLine,
                       selectPreviousPage: Qt::KeySequence::SelectPreviousPage,
                       selectPreviousWord: Qt::KeySequence::SelectPreviousWord,
                       selectStartOfBlock: Qt::KeySequence::SelectStartOfBlock,
                       selectStartOfDocument: Qt::KeySequence::SelectStartOfDocument,
                       selectStartOfLine: Qt::KeySequence::SelectStartOfLine,
                       underline: Qt::KeySequence::Underline,
                       undo: Qt::KeySequence::Undo,
                       unknownKey: Qt::KeySequence::UnknownKey,
                       whatsThis: Qt::KeySequence::WhatsThis,
                       zoomIn: Qt::KeySequence::ZoomIn,
                       zoomOut: Qt::KeySequence::ZoomOut
                     }

      # it is possible that an Qt::Enum value is passed. pe: Qt::KeySequence::Quit
      # understood symbols: all enum-elements, with first character lowercase.
      def shortcut x
#         tag "setShortcut(#{x.class} #{x.inspect})"
        x = Sym2Shortcut[x] || Qt::KeySequence::UnknownKey if Symbol === x        # first !!
        x = Qt::KeySequence.new(x) if x.is_a?(Qt::Enum)
#         tag "x is now #{x.inspect}"
        @qtc.shortcut = x
      end

      # similar for an splat of shortcuts
      def shortcuts *x
        @qtc.shortcuts = x.map do |el|
          t = Symbol === el ? (Sym2Shortcut[el] || Qt::KeySequence::UnknownKey): el
          t.is_a?(Qt::Enum) ? Qt::KeySequence.new(t) : t
        end
      end

      def checked v
        @qtc.checkable = true
        @qtc.checked = v
      end

      def value v = nil
        return instance_variable_defined(:@value) && @value unless v
        @value = v
      end

      def statustip text
        @qtc.statusTip = text
      end

      alias :statusTip :statustip

    public

      def icon= val
#         tag "icon := #{val}"
        if String === val && val[0, 7] == 'file://'
          val = Qt::Icon.new(val[7..-1])
          raise ReformError "Icon '#{val}' does not exist" if val.null?
        end
        @qtc.icon = val
      end

          # with a block, set checkable tag and connect the callback. Without a block call the toggled event
      # passing the current value of checked (this works even if no callback was registered).
      # Your callback must accept a single argument.
      def whenToggled &block
        if block
          @qtc.checkable = true
          @whenToggled = block
        else
#           tag "explicit whenToggled call"
          @qtc.toggled(@qtc.checked?)
        end
      end

      def_delegators :@qtc, :enabled=, :enabled?
  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::Action, Action

end