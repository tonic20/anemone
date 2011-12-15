require 'redis'

module Anemone
  module Storage
    
    class RedisQueue
      
      def initialize(opts = {app_prefix: "anemone:queue", key_prefix: "links"})
        @redis = ::Redis.new
        @key_prefix = (opts[:app_prefix], opts[:key_prefix]).join(":")
      end
      
      def push(element)
        @redis.lpush @key_prefix, Marshal.dump(element)
      end
      
      def shift
        Marshal.load @redis.rpop(@key_prefix)
      end
      
      def empty?
        length.zero? ? true : false
      end
      
      def length
        @redis.llen @key_prefix
      end
      
      def clear
        @redis.del @key_prefix
      end
    end
    
    class Redis

      MARSHAL_FIELDS = %w(links visited fetched)

      def initialize(opts = {})
        @redis = ::Redis.new(opts)
        @key_prefix = opts[:key_prefix] || 'anemone'
        keys.each { |key| delete(key) }
      end

      def [](key)
        rkey = "#{@key_prefix}:pages:#{key.to_s}"
        rget(rkey)
      end

      def []=(key, value)
        rkey = "#{@key_prefix}:pages:#{key.to_s}"
        hash = value.to_hash
        MARSHAL_FIELDS.each do |field|
          hash[field] = Marshal.dump(hash[field])
        end
        hash.each do |field, value|
          @redis.hset(rkey, field, value)
        end
      end

      def delete(key)
        rkey = "#{@key_prefix}:pages:#{key.to_s}"
        page = self[key]
        @redis.del(rkey)
        page
      end

      def each
        rkeys = @redis.keys("#{@key_prefix}:pages:*")
        rkeys.each do |rkey|
          page = rget(rkey)
          yield page.url.to_s, page
        end
      end

      def merge!(hash)
        hash.each { |key, value| self[key] = value }
        self
      end

      def size
        @redis.keys("#{@key_prefix}:pages:*").size
      end

      def keys
        keys = []
        self.each { |k, v| keys << k.to_s }
        keys
      end

      def has_key?(key)
        rkey = "#{@key_prefix}:pages:#{key.to_s}"
        @redis.exists(rkey)
      end

      def close
        @redis.quit
      end

      private

      def load_value(hash)
        MARSHAL_FIELDS.each do |field|
          unless hash[field].nil? || hash[field] == ''
            hash[field] = Marshal.load(hash[field]) 
          end
        end
        Page.from_hash(hash)
      end

      def rget(rkey)
        hash = @redis.hgetall(rkey)
        if !!hash
          load_value(hash)
        end
      end

    end
  end
end
