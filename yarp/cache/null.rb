require 'yarp/cache/base'

module Yarp::Cache
  class Null

    def fetch(key, ttl=nil)
      yield
    end

    def get(key)
      nil
    end

  end
end
