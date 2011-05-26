module Anemone
  module Storage
    class PersistentQueue < Queue

      def initialize(storage = [])
        super()
        @que = storage
        @que.taint
        self.taint
      end

    end
  end
end