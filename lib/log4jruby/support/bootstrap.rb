require 'thread'

Java::org.apache.log4j.Logger.class_eval do
  attr_accessor :ruby_logger
  @ruby_logger_lock = Mutex.new

  class << self
    def ruby_logger_lock
      @ruby_logger_lock
    end
  end

  def ruby_logger
    self.class.ruby_logger_lock.synchronize do
      @ruby_logger ||= Log4jruby::Logger.new(self)
    end
  end
end

# https://github.com/lenny/log4jruby/issues/14
# https://github.com/jruby/jruby/wiki/Persistence
if Java::org.apache.log4j.Logger.respond_to?(:__persistent__)
  Java::org.apache.log4j.Logger.__persistent__ = true
end

