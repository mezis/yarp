require 'singleton'
require 'forwardable'
require 'yarp/cache/memcache'
require 'yarp/cache/file'
require 'yarp/cache/null'
require 'yarp/cache/tee'
require 'yarp/cache/s3'
require 'yarp/ext/sliceable_hash'

module Yarp
  class ConcreteCache
    include Singleton
    extend Forwardable

    AVAILABLE_CACHES = {
      memcache: Yarp::Cache::Memcache.new,
      file:     Yarp::Cache::File.new,
      s3:       Yarp::Cache::S3.new,
      null:     Yarp::Cache::Null.new
    }

    def_delegators :@cache, :get, :fetch

    # This method involves all store strategies, even the ones we don't want
    # to get called during the fetching process.
    # TODO: Make sure caches only store strategies we care about
    def initialize
      @cache = Yarp::Cache::Tee.new(
        caches: get_caches,
        condition: lambda { |key, value|
          value.last.length <= ENV['YARP_CACHE_THRESHOLD'].to_i ?
            ENV['YARP_SMALL_CACHE'].to_sym :
            ENV['YARP_LARGE_CACHE'].to_sym
        }
      )
    end

    private

      def get_caches
        Hash[small_cache, AVAILABLE_CACHES[small_cache], large_cache, AVAILABLE_CACHES[large_cache]]
      end

      def small_cache
        ENV['YARP_SMALL_CACHE'] ? ENV['YARP_SMALL_CACHE'].to_sym : :null
      end

      def large_cache
        ENV['YARP_LARGE_CACHE'] ? ENV['YARP_LARGE_CACHE'].to_sym : :null
      end

  end
end
