require 'yarp'
require 'yarp/ext/sliceable_hash'
require 'yarp/cache/memcache'
require 'yarp/cache/file'
require 'yarp/cache/null'
require 'yarp/cache/tee'
require 'yarp/logger'
require 'yarp/fetcher'

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
      Log.debug "GET <#{full_request_path}>"
      cached_value = Yarp::Fetcher.fetch(full_request_path)
      if cached_value
        [200, *cached_value]
      else
        Log.info "REDIRECT <#{full_request_path}>"
        redirect "#{RUBYGEMS_URL}#{full_request_path}"
      end
    end

    def full_request_path
      if request.query_string.length > 0
        "#{request.path}?#{request.query_string}"
      else
        request.path
      end
    end
  end
end