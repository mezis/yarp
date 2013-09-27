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

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end
