require 'yarp'
require 'yarp/ext/sliceable_hash'
require 'yarp/cache/memcache'
require 'yarp/cache/file'
require 'yarp/cache/null'
require 'yarp/cache/tee'
require 'yarp/cache/s3'
require 'yarp/logger'

require 'sinatra/base'
require 'digest'
require 'uri'
require 'net/http'


module Yarp
  class App < Sinatra::Base
    RUBYGEMS_URL = ENV['YARP_UPSTREAM']

    CACHEABLE = %r{
      ^/api/v1/dependencies |
      ^/(prerelease_|latest_)?specs.*\.gz$ |
      /quick.*gemspec\.rz$ |
      ^/gems/.*\.gem$
    }x

    get CACHEABLE do
      get_cached_request(request)
    end

    get '/cache/status.json' do
      content_type :json
      Yarp::Cache::File.new.status.to_json
    end

    get '*' do
      path = full_request_path
      Log.info "REDIRECT <#{path}>"
      # $stderr.flush
      redirect "#{RUBYGEMS_URL}#{path}"
    end

  private

    Log = Yarp::Logger.new(STDERR)
    CACHE_TTL       = ENV['YARP_CACHE_TTL'].to_i
    CACHE_THRESHOLD = ENV['YARP_CACHE_THRESHOLD'].to_i

    def get_cached_request(request)
      path = full_request_path
      cache_key = Digest::SHA1.hexdigest(path)
      Log.debug "GET <#{path}> (#{cache_key})"

      headers,payload =
      cache.fetch(cache_key, CACHE_TTL) do
        uri = URI("#{RUBYGEMS_URL}#{path}")
        Log.debug "FETCH #{uri}"
        response = fetch_with_redirects(uri)
        kept_headers = response.to_hash.slice('content-type', 'content-length')
        if response.code != '200'
          return [response.code.to_i, response.to_hash, response.body]
        end

        [kept_headers, response.body]
      end

      [200, headers, payload]
    end


    def full_request_path
      if request.query_string.length > 0
        "#{request.path}?#{request.query_string}"
      else
        request.path
      end
    end


    def fetch_with_redirects(uri_str, limit = 10)
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

    Cache = Yarp::Cache::Tee.new(
      caches: {
        memcache: Yarp::Cache::Memcache.new,
        file:     Yarp::Cache::File.new,
        null:     Yarp::Cache::Null.new,
        s3:       Yarp::Cache::S3.new
      },
      condition: lambda { |key, value|
        value.last.length <= CACHE_THRESHOLD ?
          ENV['YARP_SMALL_CACHE'].to_sym :
          ENV['YARP_LARGE_CACHE'].to_sym
      })

    def cache
      Cache
    end
  end
end
