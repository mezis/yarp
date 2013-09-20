require 'yarp/cache/base'
require 'yarp/logger'
require 'pathname'
require 'uri'

module Yarp::Cache
  # A cache store implementation which stores everything on the filesystem.
  #
  class S3 < Base


    # Log = Yarp::Logger.new(STDERR)


    def get(key)

    end


    def fetch(key) # Check if TTL can be setup

    end


    def _connection
      @_connection ||= Fog::Storage.new(
        :provider              => 'AWS',
        :aws_access_key_id     => ENV['AWS_ACCESS_KEY_ID'],
        :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
      )
    end


    def _directory
      @_directory ||= connection.directories.new(
        :key    => ENV['AWS_BUCKET_NAME'],
        :public => true
      )
    end


    # def upload(file_path)
    #   file = _directory.files.create(
    #     :key    => 'file_name',
    #     :body   => File.open(file_path)
    #   )
    # end


  end
end
