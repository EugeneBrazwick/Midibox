
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
    end
  end
end