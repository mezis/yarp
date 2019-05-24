# frozen_string_literal: true

require_relative 'base'

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
