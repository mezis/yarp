require 'yarp/fetcher/queue'
require 'yarp/fetcher'

module Yarp
  class Fetcher
    module Spawner

      extend self
      FETCHING_THREADS = 4

      def spawn_fetching_threads
        FETCHING_THREADS.times do
          spawn_fetching_thread
        end
      end

      def spawn_fetching_thread
        thread = Thread.new do
          begin
            while fetcher = Queue.instance.pop
              begin
                fetcher.fetch_from_upstream
              ensure
                Queue.instance.done(fetcher)
              end
            end
          rescue Exception => e
            spawn_fetching_thread
            raise e
          end
        end
        thread
      end
    end
  end
end
