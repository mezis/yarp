module Yarp;end
require 'yarp/ext/sliceable_hash'
require 'yarp/cache/memcache'
require 'yarp/cache/file'
require 'yarp/cache/null'
require 'yarp/cache/tee'
require 'yarp/logger'
require 'yarp/fetcher'


Yarp::Log = Yarp::Logger.new(STDERR)
