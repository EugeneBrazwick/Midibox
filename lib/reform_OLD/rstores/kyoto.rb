
# nil rstore backend. Does not support storage

require 'kyotocabinet'

module Reform
  module RStoreBackend
    class KyotoCabinet < ::KyotoCabinet::DB
      include ::KyotoCabinet
      private
        def initialize path, opts = nil
          super(DB::GEXCEPTIONAL)
            open(path, DB::OWRITER | DB::OCREATE)
        end
      public
    end
  end
end