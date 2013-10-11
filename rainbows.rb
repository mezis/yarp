# Rainbows-specific configuration

Rainbows! do
  use :ThreadPool                        # concurrency model to use
  worker_connections        ENV['UNICORN_THREADS'].to_i
  keepalive_timeout         ENV['UNICORN_KEEPALIVE'].to_i # zero disables keepalives entirely
  client_max_body_size      1_024        # 1KB
  keepalive_requests        100          # default:100
  client_header_buffer_size 2_048        # 2 kilobytes
end

# Sample verbose configuration file for Unicorn (not Rack)
#
# This configuration file documents many features of Unicorn
# that may not be needed for some applications. See
# http://unicorn.bogomips.org/examples/unicorn.conf.minimal.rb
# for a much simpler configuration file.
#
# See http://unicorn.bogomips.org/Unicorn/Configurator.html for complete
# documentation.

# Use at least one worker per core if you're on a dedicated server,
# more will usually help for _short_ waits on databases/caches.
worker_processes ENV['UNICORN_WORKERS'].to_i

# Since Unicorn is never exposed to outside clients, it does not need to
# run on the standard HTTP port (80), there is no reason to start Unicorn
# as root unless it's from system init scripts.
# If running the master process as root and the workers as an unprivileged
# user, do this to switch euid/egid in the workers (also chowns logs):
# user "unprivileged_user", "unprivileged_group"

# Help ensure your application will always spawn in the symlinked
# "current" directory that Capistrano sets up.
# working_directory "/path/to/app/current" # available in 0.94.0+

# listen on both a Unix domain socket and a TCP port,
# we use a shorter backlog for quicker failover when busy
# listen "/tmp/.sock", :backlog => 64
# listen 8080, :tcp_nopush => true

# nuke workers after X seconds instead of 60 seconds (the default)
timeout ENV['UNICORN_TIMEOUT'].to_i

# feel free to point this anywhere accessible on the filesystem
# pid "/path/to/app/shared/pids/unicorn.pid"

# By default, the Unicorn logger will write to stderr.
# Additionally, ome applications/frameworks log to stderr or stdout,
# so prevent them from going to /dev/null when daemonized here:
# stderr_path "/path/to/app/shared/log/unicorn.stderr.log"
# stdout_path "/path/to/app/shared/log/unicorn.stdout.log"

# combine Ruby 2.0.0dev or REE with "preload_app true" for memory savings
# http://rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
preload_app true
GC.respond_to?(:copy_on_write_friendly=) and
  GC.copy_on_write_friendly = true

# Enable this flag to have unicorn test client connections by writing the
# beginning of the HTTP headers before calling the application.  This
# prevents calling the application for connections that have disconnected
# while queued.  This is only guaranteed to detect clients on the same
# host unicorn runs on, and unlikely to detect disconnects even on a
# fast LAN.
check_client_connection false

before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end
end

after_fork do |server, worker|
  Yarp::Fetcher::Spawner.spawn_fetching_threads
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to sent QUIT'
  end
end
