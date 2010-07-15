require 'logging'
require 'memcache'
require 'reretryable'

module MegaMutex
  class TimeoutError < Exception; end

  class DistributedMutex
    include Retryable

    class << self
      def cache
        @cache ||= MemCache.new MegaMutex.configuration.memcache_servers, :namespace => MegaMutex.configuration.namespace
      end
    end

    def initialize(key, options)
      @key = key
      @lazy = options[:lazy]
      @timeout = options[:timeout] || 30
    end

    def logger
      Logging::Logger[self]
    end

    def run(&block)
      @start_time = Time.now
      log "Attempting to lock mutex..."
      lock!
      log "Locked. Running critical section..."
      result = yield
      log "Critical section complete. Unlocking..."
      result
    ensure
      unlock!
      log "Unlocking Mutex."
    end
    
    def current_lock
      cache.get(@key)
    end
    
  private
    def with_retry(&block)
      if @lazy
        return yield block
      else
        retryable(:tries => 5, :sleep => 30, :on => MemCache::MemCacheError, :matching => /IO timeout/) do
          return yield block
        end
      end
    end
    
    def with_lazy(&block)
      if @lazy
        begin
          return yield block
        rescue MemCache::MemCacheError => exception
          log("There was a memcache error that was ignored:\n#{exception.class} (#{exception.message}):\n  #{exception.backtrace.join("\n  ")}\n\n")
        rescue TimeoutError => exception
          log("There was a timeout error that was ignored")
        end
      else
        return yield block
      end
    end
  
    def timeout?
      return false unless @timeout
      Time.now > @start_time + @timeout
    end
  
    def log(message)
      logger.debug { "(key:#{@key}) (lock_id:#{my_lock_id}) #{message}" }
    end

    def lock!
      with_lazy do
        until timeout?
          with_retry do
            return if attempt_to_lock == my_lock_id
            sleep 0.1
          end
        end
        raise TimeoutError.new("Failed to obtain a lock within #{@timeout} seconds.") unless @lazy
      end
    end
    
    def attempt_to_lock
      set_current_lock(my_lock_id) if current_lock.nil?
      current_lock
    end
    
    def unlock!
      with_lazy do
        with_retry do
          cache.delete(@key) if locked_by_me?
          return #explicit return so we quit out of the block
        end
      end
    end
    
    def locked_by_me?
      current_lock == my_lock_id
    end
    
    def set_current_lock(new_lock)
      cache.add(@key, my_lock_id)      
    end
    
    def my_lock_id
      @my_lock_id ||= "#{Process.pid.to_s}.#{self.object_id.to_s}.#{Time.now.to_i.to_s}"
    end

    def cache
      self.class.cache
    end
  end
end
