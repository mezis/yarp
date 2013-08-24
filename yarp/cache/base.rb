require 'yarp'

module Yarp::Cache
  class Base

    def fetch(key, ttl=nil)
      raise NotImplementedError("#{self.class.name} is abstract")
    end

    def get(key)
      raise NotImplementedError("#{self.class.name} is abstract")
    end

  end
end