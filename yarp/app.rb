require 'sinatra/base'
require 'dalli'
require 'digest'
require 'uri'
require 'net/http'
require 'newrelic_rpm'

RUBYGEMS_URL = 'http://rubygems.org'

if defined? Unicorn
  NewRelic::Agent.after_fork(:force_reconnect => true)
end

module Ext
  module SliceableHash
    def slice(*keys)
      select { |k,v| keys.include?(k) }
    end

    ::Hash.send :include, self
  end
end

module Yarp
  class App < Sinatra::Base

    get '/api/v1/dependencies*' do
      path = "#{request.path}?#{request.query_string}"
      cache_key = Digest::SHA1.hexdigest(path)

      headers,payload =
      cache.fetch(cache_key, ENV['CACHE_TTL_SECONDS'].to_i) do
        uri = URI("#{RUBYGEMS_URL}#{path}")
        response = Net::HTTP.get_response(uri)
        kept_headers = response.to_hash.slice('Content-Type')
        if response.code != '200'
          return [response.code.to_i, kept_headers, response.body]
        end

        [kept_headers, response.body]
      end

      # $stderr.puts "GET <#{path}>"
      # $stderr.puts headers.inspect
      # $stderr.puts headers.inspect, payload.inspect
      # $stderr.flush
      [200, headers, payload]
    end

    get '*' do
      path = "#{request.path}?#{request.query_string}"
      # $stderr.puts "REDIRECT <#{path}>"
      # $stderr.flush
      redirect "#{RUBYGEMS_URL}#{path}"
    end

  private

    def cache
      @cache_connection ||= 
        Dalli::Client.new(
          ENV['MEMCACHIER_SERVERS'].split(','),
          username: ENV['MEMCACHIER_USERNAME'],
          password: ENV['MEMCACHIER_PASSWORD'],
          compress:true)
    end
  end
end