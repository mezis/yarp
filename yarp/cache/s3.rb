require 'yarp/cache/base'
require 'yarp/logger'
require 'fog'
require 'pry'

module Yarp::Cache
  # A cache store implementation which stores everything on the filesystem.
  #
  class S3 < Base


    # Log = Yarp::Logger.new(STDERR)


    def get(key)
      puts key
      _directory.files.get(key)
    end


    def fetch(key, ttl=nil) # Check if TTL can be setup
      value = get(key) and return value
      value = yield
      _upload(key, value, ttl)
    end


    private


      def _connection
        @_connection ||= Fog::Storage.new(
          :provider              => 'AWS',
          :aws_access_key_id     => ENV['AWS_ACCESS_KEY_ID'],
          :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
        )
      end


      def _directory
        @_directory ||= _connection.directories.new(
          :key    => ENV['AWS_BUCKET_NAME'],
          :public => true
        )
      end


      def _upload(key, value, ttl)
        file = _directory.files.create(
          :key    => key,
          :body   => value.respond_to?(:first) ? Marshal.dump(value) : value
        )
      end


  end
end
