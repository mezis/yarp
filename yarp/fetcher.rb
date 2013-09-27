module Yarp
  class Fetcher

    @paths_being_fetched = {}

    singleton_class.class_eval do
      attr_accessor :paths_being_fetched
    end

    def self.fetch(path)
      new(path).fetch
    end

    def initialize(path)
      @path = path
    end

    def fetch
      cached_value = self.class.cache.get(cache_key)
      return cached_value if cached_value
      async_fetch
      return
    end

    def self.cache
      @cache ||= Yarp::Cache::Tee.new(
        caches: {
          memcache: Yarp::Cache::Memcache.new,
          file:     Yarp::Cache::File.new,
          null:     Yarp::Cache::Null.new
        },
        condition: lambda { |key, value|
          value.last.length <= CACHE_THRESHOLD ?
            ENV['YARP_SMALL_CACHE'].to_sym :
            ENV['YARP_LARGE_CACHE'].to_sym
        }
      )
    end

    private

    def async_fetch
      return if self.path_being_fetched[@path]
      self.path_being_fetched[@path] = Thread.new(@path, cache_key) do |request_path, key|
        self.class.cache.fetch(key, CACHE_TTL) do
          uri = URI("#{RUBYGEMS_URL}#{request_path}")
          Log.debug "FETCH #{uri}"
          response = self.class.fetch_with_redirects(uri)
          kept_headers = response.to_hash.slice('content-type', 'content-length')
          if response.code != '200'
            return [response.code.to_i, response.to_hash, response.body]
          end
          [kept_headers, response.body]
        end
        self.path_being_fetched.delete(request_path)
      end
    end

    def self.fetch_with_redirects(uri_str, limit = 10)
      while limit > 0
        begin
          response = Net::HTTP.get_response(URI(uri_str))
        rescue SocketError => e
          Log.error("#{SocketError}: #{e.message}")
          limit  -= 1
          next
        end

        case response
        when Net::HTTPRedirection then
          uri_str = response['location']
          limit  -= 1
        else
          return response
        end
      end
      raise RuntimeError('too many HTTP redirects') if limit == 0
    end

    def cache_key
      @cache_key ||= Digest::SHA1.hexdigest(@path)
    end
  end
end