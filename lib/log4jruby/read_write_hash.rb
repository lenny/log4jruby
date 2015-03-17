
module Log4jruby

  # Pure Ruby Hash with a protection of ReadWriteLock for thread-safety
  class ReadWriteHash

    def initialize
      @kvhash = {}
      @rwlock = Java::java.util.concurrent.locks.ReentrantReadWriteLock.new
      @rlock = @rwlock.readLock
      @wlock = @rwlock.writeLock
    end

    def [] (key)
      begin
        @rlock.lock
        return @kvhash[key] 
      ensure
        @rlock.unlock
      end
    end

    def []= (key, value)
      begin
        @wlock.lock
        @kvhash[key] = value
      ensure
        @wlock.unlock
      end
    end

  end

end
