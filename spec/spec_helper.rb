$:.unshift File.expand_path('../..', __FILE__)
require 'yarp'
require 'webmock/rspec'
require 'stringio'
require 'pry'

# Load env variables with foreman
require 'foreman/engine'
Foreman::Engine.new.load_env('.env').each_pair do |key, value|
  ENV[key] = value
end

ENV['YARP_FILECACHE_PATH'] = 'tmp/test_cache'
Yarp::Log.sev_threshold = Logger::FATAL

RSpec.configure do |config|
  config.order = 'random'
end
