require 'thread'
require 'singleton'
require 'forwardable'

module Yarp
  class Fetcher
    class Queue
      include Singleton
      extend Forwardable

      def_delegators :@queue, :pop, :length

      def initialize
        @queue = ::Queue.new
        @queued_paths = []
      end

      def <<(fetcher)
        Mutex.new.synchronize do
          return nil if @queued_paths.include?(fetcher.path)
          @queued_paths << fetcher.path
        end
        @queue << fetcher
      end

      def done(fetcher)
        @queued_paths.delete(fetcher.path)
      end

      def clear
        initialize
      end
    end
  end
end