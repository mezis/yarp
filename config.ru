lib = File.expand_path('../', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

if ENV['YARP_DISABLE_DOTENV'].empty?
  require 'dotenv'
  Dotenv.load!
end

require 'yarp/app'
require 'yarp/initializers/new_relic'

run Yarp::App
