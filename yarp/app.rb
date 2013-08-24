require 'yarp'
require 'yarp/ext/sliceable_hash'
require 'yarp/cache/memcache'
require 'yarp/cache/null'
require 'yarp/cache/tee'
require 'yarp/logger'

require 'sinatra/base'
require 'digest'
require 'uri'
require 'net/http'

RUBYGEMS_URL = 'http://rubygems.org'

module Yarp
  class App < Sinatra::Base

    get '/api/v1/dependencies*' do
      get_cached_request(request)
    end

    get %r{/(prerelease_)?specs.*\.gz|/quick.*gemspec.rz} do
      get_cached_request(request)
    end


    get '*' do
      path = full_request_path
      Log.info "REDIRECT <#{path}>"
      # $stderr.flush
      redirect "#{RUBYGEMS_URL}#{path}"
    end

  private

    Log = Yarp::Logger.new(STDERR)
    CACHE_TTL = ENV['CACHE_TTL_SECONDS'].to_i

    def get_cached_request(request)
      path = full_request_path
      cache_key = Digest::SHA1.hexdigest(path)
      Log.info "GET <#{path}> (#{cache_key})"

      headers,payload =
      cache.fetch(cache_key, CACHE_TTL) do
        uri = URI("#{RUBYGEMS_URL}#{path}")
        Log.debug "FETCH #{uri}"
        response = fetch_with_redirects(uri)
        Log.debug "  >> #{response.code}"
        Log.debug "  >> #{response.to_hash}"
        kept_headers = response.to_hash.slice('content-type', 'content-length')
        if response.code != '200'
          return [response.code.to_i, response.to_hash, response.body]
        end

        [kept_headers, response.body]
      end

      Log.debug headers.inspect
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
        response = Net::HTTP.get_response(URI(uri_str))

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
        null:     Yarp::Cache::Null.new
      },
      condition: lambda { |key, value|
        value.first['content-length'].first.to_i <= 850_000 ? :memcache : :null
      })

    def cache
      Cache
    end
  end
end