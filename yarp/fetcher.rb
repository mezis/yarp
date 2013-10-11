require 'digest'
require 'uri'
require 'net/http'
require 'thread'
require 'yarp/concrete_cache'
require 'yarp/fetcher/queue'
require 'yarp/fetcher/spawner'

module Yarp
  class Fetcher
    FETCH_REDIRECTS_LIMIT = 10

    attr_reader :path

    def initialize(path)
      @path = path
    end

    def perform
      cached_value = Yarp::ConcreteCache.instance.get(cache_key)
      return cached_value if cached_value
      Yarp::Fetcher::Queue.instance << self
      return
    end

    def fetch_from_upstream
      Yarp::ConcreteCache.instance.fetch(cache_key, ENV['YARP_CACHE_TTL'].to_i) do
        Log.debug "FETCH #{@path}"
        response = fetch_with_redirects
        kept_headers = response.to_hash.slice('content-type', 'content-length')
        if response.code != '200'
          return [response.code.to_i, response.to_hash, response.body]
        end
        [kept_headers, response.body]
      end
    end

    private

    def fetch_with_redirects
      limit = FETCH_REDIRECTS_LIMIT
      uri_str = "#{ENV['YARP_UPSTREAM']}#{@path}"

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
