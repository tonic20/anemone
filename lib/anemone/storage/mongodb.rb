begin
  require 'mongo'
rescue LoadError
  puts "You need the mongo gem to use Anemone::Storage::MongoDB"
  exit
end

module Anemone
  module Storage
    class MongoDB 

      BINARY_FIELDS = %w(body headers)

      def initialize(mongo_db, collection_name, options)
        @db = mongo_db
        @collection = @db[collection_name]

        if options[:flush]
          @collection.remove
          @collection.create_index 'url'
          @collection.create_index 'digest'
          @collection.create_index 'data.content'
        end
      end

      def [](url)
        if value = @collection.find_one('url' => url.to_s)
          load_page(value)
        end
      end

      def []=(url, page)
        hash = page.to_hash
        BINARY_FIELDS.each do |field|
          hash[field] = BSON::Binary.new(hash[field]) unless hash[field].nil?
        end
        @collection.update(
          {'url' => page.url.to_s},
          hash,
          :upsert => true
        )
      end

      def delete(url)
        page = self[url]
        @collection.remove('url' => url.to_s)
        page
      end

      def each
        @collection.find do |cursor|
          cursor.each do |doc|
            page = load_page(doc)
            yield page.url.to_s, page 
          end
        end
      end

      def merge!(hash)
        hash.each { |key, value| self[key] = value }
        self
      end

      def size
        @collection.count
      end

      def keys
        keys = []
        self.each { |k, v| keys << k.to_s }
        keys
      end

      def has_key?(url)
        !!@collection.find_one('url' => url.to_s)
      end

      def has_digest?(url, page_digest)
        !!@collection.find_one('url' => /^#{url}/i, 'digest' => page_digest)
      end

      def has_duplicate_content?(url, content_digest)
        !!@collection.find_one('url' => /^#{url}/i, 'data.content' => content_digest)
      end

      def close
        @db.connection.close
      end

      private

      def load_page(hash)
        BINARY_FIELDS.each do |field|
          hash[field] = hash[field].to_s
        end
        Page.from_hash(hash)
      end
    end
  end
end
