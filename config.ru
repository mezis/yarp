lib = File.expand_path('../', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'dotenv'
Dotenv.load!

require 'yarp/app'
require 'yarp/initializers/new_relic'

run Yarp::App
