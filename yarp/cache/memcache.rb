# frozen_string_literal: true

require 'dalli'

require_relative 'base'

module Yarp::Cache
  class Memcache

    def fetch(key, ttl=nil)
      _connection.fetch(key, ttl) { yield or return }
    end

    def get(key)
      _connection.get(key)
    end

    private

    def _connection
      @_connection ||= Dalli::Client.new(
        ENV['MEMCACHIER_SERVERS'].split(','),
        username: ENV['MEMCACHIER_USERNAME'],
        password: ENV['MEMCACHIER_PASSWORD'],
        compress: true)
    end
  end
end
