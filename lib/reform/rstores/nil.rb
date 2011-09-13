
# nil rstore backend. Does not support storage

module Reform
  module RStoreBackend
    class Nil < ::Hash
#       private
#         def initialize
#           @storage = {}
#         end
#       public
#         def [] key
#           @storage[key]
#         end
#         
#         def []= key, value
#           @storage[key] = value
#         end
      public
        def closed?
          false
        end
           
        def begin_transaction sync = false
        end
        
        def end_transaction commit = true
        end

    end
  end
end