$:.unshift File.expand_path('../..', __FILE__)
require 'yarp'
require 'webmock/rspec'
require 'pry'
require 'dotenv'

Dotenv.load

ENV['YARP_FILECACHE_PATH'] = 'tmp/test_cache'
Yarp::Log.sev_threshold = Logger::FATAL

RSpec.configure do |config|
  config.order = 'random'

  # TODO: Remove all Fog/S3 related configurations when Tee doesn't involve
  # s3 cache on each and every fetch
  config.before(:all) do
    ENV['AWS_ACCESS_KEY_ID']     = '123'
    ENV['AWS_SECRET_ACCESS_KEY'] = '123'
    ENV['AWS_BUCKET_NAME']       = 'yarp_test'

    Fog.mock!
  end

  config.before(:each) do

    Fog::Mock.reset

    connection = Fog::Storage.new({
      :provider              => 'AWS',
      :aws_access_key_id     => ENV['AWS_ACCESS_KEY_ID'],
      :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
    })

    directory = connection.directories.create(
      :key    => ENV['AWS_BUCKET_NAME'],
      :public => true
    )

    Yarp::Cache::S3.any_instance.stub(
      :_connection => connection,
      :_directory  => directory
    )
  end
end
