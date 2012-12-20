
# Copyright (c) 2010 Eugene Brazwick

require 'Qt'

module Reform
=begin
    qtruby undostack stuff is BROKEN BEYOND REPAIR.

    So need to workaround.

    In the process the 'merging' of commands is no longer supported!!
=end

  class QUndoGroup < Qt::UndoGroup
    public
      def push cmd
        activeStack.push cmd
      end
  end

  class QUndoStack < Qt::UndoStack
    private
      def initialize parent
        super
        @shadowstack = []
      end

    public
      def push command
        raise 'uh oh' unless command.id == -1 # see comments
        super
        @shadowstack << command
      end

      def clear
        super
        @shadowstack = []
      end
  end

# DO NOT USE: id or mergeWith!!!!!
#
# Some advise: 'creator' commands should store a reference to what they create
# and not a recipy to recreate something.
# This is rather fundamental.
# Later commands will refer to the created instance and if you undo and redo
# the whole stack the same objects must be created!
#
# And another: create the command only if the user has completed his action.
#
  class QUndoCommand < Qt::UndoCommand
    private
      def initialize text, parent = nil
        if parent
          super
        else
          super(text) # # , $errrrm)            They accumulate, but it still crashes!!!!
        end
#         tag "$errrrm now has #{$errrrm.childCount} children"
#         @bogo = self # reference ourselves to prevent premature garbage collect                NO EFFECT
          # this means the GC never marks the contents of the undostacks...
      end
  end
end