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
end
