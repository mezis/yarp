require 'yarp/cache/base'
require 'yarp/logger'
require 'pathname'
require 'uri'

module Yarp::Cache
  # A cache store implementation which stores everything on the filesystem.
  # 
  class File < Base
    attr_reader :_cache_path
    attr_reader :_max_bytes


    def initialize(cache_path:nil, max_bytes:nil)
      @_cache_path = cache_path ? cache_path.to_s : Pathname(ENV['YARP_FILECACHE_PATH'])
      @_max_bytes  = max_bytes  ? max_bytes.to_i  : ENV['YARP_FILECACHE_MAX_BYTES'].to_i
    end


    def get(key)
      now = Time.now.to_i
      _edit_metadata do |metadata|
        value = metadata[:files].delete(key)
        return unless value

        size,access,expiry = value
        if expiry < now
          _remove_expired
          return
        end

        metadata[:files][key] = [size,now,expiry]
        return Marshal.load(_cache_file(key).read)
      end
    end


    def fetch(key, ttl=nil)
      value = get(key) and return value
      value = yield
      _set(key, value, ttl)
    end

    def status
      _edit_metadata do |metadata|
        return { keys:metadata[:files].size, bytes:metadata[:bytes], size:_max_bytes }
      end
    end


    def flush
      _flush
    end


    # private

    Log = Yarp::Logger.new(STDERR)

    # schema for metadata
    # each file entry maps a key (the filename) to 3 integers: the size, the
    # timestamp of last usage and timestamp of expiry.
    # the first file is the least recently used.
    def _default_meta
      { bytes:0, files:{} }
    end


    # path to the file holding cache metadata
    def _meta_path
      @_meta_path ||= _cache_path.join('meta')
    end

    # path to the file used to store +key+
    def _cache_file(key)
      escaped_key = URI.encode_www_form_component(key)
      _cache_path.join(escaped_key)
    end

    # empties the whole cache
    def _flush
      _edit_metadata do |metadata|
        _cache_path.children.each do |child|
          child.rmtree unless child == _meta_path
        end
        metadata.replace(DEFAULT_META)
      end
    end

    # write a value to the cache
    def _set(key, value, ttl=nil)
      ttl  ||= 365 * 86400 # 1 year
      now    = Time.now.to_i
      expiry = now + ttl
      data   = Marshal.dump(value)
      size   = data.bytesize

      # require 'pry' ; require 'pry-nav' ; binding.pry
      _delete(key)
      _make_space_for(size)
      _cache_file(key).open('w') { |io| io.write(data) }
      _edit_metadata do |metadata|
        metadata[:bytes] += data.bytesize
        metadata[:files][key] = [size,now,expiry]
      end

      return value
    end

    def _delete(key)
      _edit_metadata do |metadata|
          size,_,_ = metadata[:files][key]
          return false if size.nil?
          metadata[:bytes] -= size
          metadata[:files].delete(key)
      end
      _cache_file(key).delete
      return true
    end

    # removes expired cache entries (files) and updates metadata
    def _remove_expired
      now = Time.now.to_i
      _edit_metadata do |metadata|
        files_to_delete = []
        metadata[:files].each_pair do |key,(size, _, expires)|
          next unless expires < now
          _cache_file(key).delete
          metadata[:bytes] -= size
          metadata[:files].delete(key)
        end
      end
    end

    # removes files from the cache until there is enought space for +bytes+
    def _make_space_for(bytes)
      raise ArgumentError("cannot store files larger than the cache") if bytes > _max_bytes
      _edit_metadata do |metadata|
        while bytes > _max_bytes - metadata[:bytes]
          key,(size,_,_) = metadata[:files].first
          Log.warn "FILECACHE evicting #{key}"
          _cache_file(key).delete
          metadata[:files].delete(key)
          metadata[:bytes] -= size
        end
      end
    end

    # executes the given block while holding a lock on the meta file.
    # yield an IO for the meta file.
    # reentrant (yields the same descriptor if called recursively).
    def _with_lock
      return yield @_meta_fd if @_meta_fd
      _meta_path.parent.mkpath
      _meta_path.open(::File::CREAT | ::File::RDWR) do |io|
        begin
          @_meta_fd = io
          io.flock(::File::LOCK_EX)
          yield @_meta_fd
        ensure
          io.flock(::File::LOCK_UN)
          @_meta_fd = nil
        end
      end
    end

    # yields the current metadata (should be a mutable hash).
    # writes data back (even if unmodified) after running the block.
    # implicitly locks the metadata file.
    # reentrant (nested calls are passed the same mutable hash).
    def _edit_metadata
      return yield @_metadata if @_metadata
      _with_lock do |io|
        io.seek(0)
        raw = io.read()
        @_metadata = begin
          raw.length == 0 ? _default_meta.dup : Marshal.load(raw)
        rescue ArgumentError, TypeError
          Log.warn("FILECACHE resetting broken metatada")
          _default_meta.dup
        end

        begin
          yield @_metadata
        ensure
          # Log.debug("FILECACHE metadata before write #{@_metadata.inspect}")
          raw = Marshal.dump(@_metadata)

          io.seek(0)
          io.truncate(raw.bytesize)
          io.write(raw)
          io.flush
          @_metadata = nil
        end
      end
    end


  end
end
