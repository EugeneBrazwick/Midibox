
# nil rstore backend. Does not support storage

require 'gdbm'

module Reform
  module RStoreBackend
    class GDBM < ::GDBM
      private
        def initialize path, opts = nil
          super 
        end
      public
    end
  end
end