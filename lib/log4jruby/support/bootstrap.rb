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
