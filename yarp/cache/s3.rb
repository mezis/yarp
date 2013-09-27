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
      #_directory.files.get(key)
      _read(key)
    end


    def fetch(key, ttl=nil) # Check if TTL can be setup
      value = get(key) and return value
      value = yield
      #_upload(key, value, ttl)
      _save(key, value, ttl)
    end


    private


      def _save(key, value, ttl)
        # Check if we're dealing with a binary or not
        if value.last.encoding.to_s == "ASCII-8BIT"
          file = ::File.open("files/#{key}.gz", 'wb')
          file.write(value.last)
          file.close
        end

        value_for_saving = value.

        file = ::File.open("files/#{key}", 'w')
        file.write(Marshal.dump(value))
        file.close

        value
      end


      def _read(key)
        if ::File.exist?("files/#{key}")
          file = ::File.open("files/#{key}", 'r')
          value = Marshal.load(file.read)

          if ::File.exist?("files/#{key}.gz")
            file = ::File.open("files/#{key}.gz", 'rb')
            value.last.replace(file.read)
            file.close
          end


          value
        end
      end


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
