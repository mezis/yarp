# frozen_string_literal: true

module Yarp::Ext
  module SliceableHash
    def slice(*keys)
      select { |k,v| keys.include?(k) }
    end

    ::Hash.send :include, self
  end
end
