
# nil rstore backend. Does not support storage

require 'gdbm'

module Reform
  module RStoreBackend
    class GDBM < ::GDBM
      private
        def initialize path, opts = nil
          super(path, 0666, nil)
        end
      public
        def begin_transaction sync = false
        end
        
        def end_transaction commit = true
        end
    end
  end
end