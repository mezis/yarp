lib = File.expand_path('../', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'yarp/app'
require 'yarp/initializers/new_relic'
require 'yarp/fetcher'

Yarp::Fetcher::Spawner.spawn_fetching_threads
run Yarp::App
