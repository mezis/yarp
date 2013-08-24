require 'yarp/cache/base'
require 'yarp/logger'

module Yarp::Cache
  class Tee
    attr_reader :_caches
    attr_reader :_condition

    Log = Yarp::Logger.new(STDERR)

    # - condition: proc that accepts a key and payload size, and yields a symbol
    # - caches: a hash of symbols to caches
    # 
    # All symbols listed by the +condition+ must be in the +caches+.
    # 
    def initialize(condition:nil, caches:nil)
      @_caches    = caches
      @_condition = condition
    end


    def get(key)
      _caches.each_pair do |cache_name, cache|
        next unless v = cache.get(key)
        Log.info "TEE cache hit #{key} <- #{cache_name}"
        return v
      end
      nil
    end


    def fetch(key, ttl)
      v = get(key) and return v
      value = yield
      cache_name = _condition.call(key, value)
      Log.warn "TEE cache miss #{key} -> #{cache_name} (ttl #{ttl})"
      _caches[cache_name].fetch(key, ttl) { value }
    end

  end
end
