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
      file = _directory.files.get(key)
      if file
        value = Marshal.load(file.body)
        result = [value.first, Base64.strict_decode64(value.last)]
      end
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
          :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
          :region                => 'eu-west-1'
        )
      end


      def _directory
        @_directory ||= _connection.directories.new(
          :key    => ENV['AWS_BUCKET_NAME'],
          :public => true
        )
      end


      def _upload(key, value, ttl)
        headers, body = value
        saving_value = [headers, Base64.strict_encode64(body)]

        file = _directory.files.create(
          :key    => key,
          :body   => Marshal.dump(saving_value)
        )
        value
      end


  end
end
