# frozen_string_literal: true

require 'pathname'
require 'uri'

require_relative 'base'
require_relative '../logger'

module Yarp::Cache
  # A cache store implementation which stores everything on the filesystem.
  # 
  class File < Base
    attr_reader :_cache_path
    attr_reader :_max_bytes

    def initialize(cache_path:nil, max_bytes:nil)
      @_cache_path = Pathname.new(
        cache_path || Pathname(ENV['YARP_FILECACHE_PATH'])
      )
      @_max_bytes  = (max_bytes || ENV['YARP_FILECACHE_MAX_BYTES']).to_i
    end

    def get(key)
      now = Time.now.to_i
      _metadata do |m|
        if !(f_data = m[:files][key])
          return
        end

        if f_data[2] < now
          m[:files].delete(key)
          return
        end

        m[:files][key][1] = now
        return Marshal.load(_cache_file(key).read)
      end
    end

    def fetch(key, ttl=nil)
      if value = get(key)
        return value
      end

      value = yield
      _metadata do |m|
        ttl ||= 365 * 86400 # 1 year
        now = Time.now.to_i
        expiry = now + ttl
        data = Marshal.dump(value)
        size = data.bytesize

        _delete_expired(m)
        _make_space_for(m, size)
        _cache_file(key).write(data)

        m[:bytes] += data.size
        m[:files][key] = [size, now, expiry]
      end
      value
    end

    def status
      _edit_metadata do |metadata|
        return {
          keys: metadata[:files].size,
          bytes: metadata[:bytes],
          size: _max_bytes
        }
      end
    end

    LOG = Yarp::Logger.new(STDERR)
    private_constant :LOG
    LOCK = Mutex.new
    private_constant :LOCK

    # schema for metadata
    # each file entry maps a key (the filename) to 3 integers: the size, the
    # timestamp of last usage and timestamp of expiry.
    private def _default_meta
      {
        bytes: 0,
        files: {},
      }
    end


    # path to the file holding cache metadata
    private def _meta_path
      @_meta_path ||= _cache_path.join('meta')
    end

    # path to the file used to store +key+
    private def _cache_file(key)
      escaped_key = URI.encode_www_form_component(key)
      _cache_path.join(escaped_key)
    end

    private def _delete(m, key)
      size = m[:files][key][0]

      m[:bytes] -= size
      m[:files].delete(key)
      _cache_file(key).delete
    end

    # removes expired cache entries (files) and updates metadata
    private def _delete_expired(m)
      now = Time.now.to_i
      m[:files].each_pair do |key, (_, _, expiry)|
        next unless expiry < now
        _delete(m, key)
      end
    end

    # removes files from the cache until there is enought space for +bytes+
    private def _make_space_for(m, bytes)
      if bytes > _max_bytes
        raise ArgumentError("cannot store files larger than the cache")
      end

      m[:files].sort_by { |f_data| f_data[1] }.each do |key, _|
        return if bytes < _max_bytes - m[:bytes]

        LOG.warn "FILECACHE evicting #{key}"
        _delete(m, key)
      end
    end

    # executes the given block while holding a lock on the meta file.
    # yield an IO for the meta file.
    private def _with_flock(path)
      path.parent.mkpath
      LOCK.synchronize do
        path.open(::File::CREAT | ::File::RDWR) do |io|
          io.flock(::File::LOCK_EX)
          yield io
        ensure
          io.flock(::File::LOCK_UN)
        end
      end
    end

    # yields the current metadata (should be a mutable hash).
    # writes data back (even if unmodified) after running the block.
    # implicitly locks the metadata file.
    private def _metadata
      _with_flock(_meta_path) do |io|
        io.seek(0)
        raw = io.read()

        metadata = begin
                     raw.length == 0 ? _default_meta.dup : Marshal.load(raw)
                   rescue ArgumentError, TypeError
                     LOG.warn("FILECACHE resetting broken metatada")
                     _default_meta.dup
                   end

        begin
          yield metadata
        ensure
          raw = Marshal.dump(metadata)

          io.seek(0)
          io.truncate(raw.bytesize)
          io.write(raw)
          io.flush
        end
      end
    end
  end
end
