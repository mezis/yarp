# frozen_string_literal: true

require 'dotenv'
Dotenv.load!

require_relative 'yarp/app'

run Yarp::App
