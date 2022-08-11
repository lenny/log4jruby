# frozen_string_literal: true

Java::org.apache.log4j.Logger.class_eval do
  attr_accessor :ruby_logger

  @ruby_logger_lock = Mutex.new

  class << self
    attr_reader :ruby_logger_lock
  end

  def ruby_logger
    self.class.ruby_logger_lock.synchronize do
      @ruby_logger ||= Log4jruby::Logger.new(self)
    end
  end
end

# https://github.com/lenny/log4jruby/issues/14
# https://github.com/jruby/jruby/wiki/Persistence
Java::org.apache.log4j.Logger.__persistent__ = true if Java::org.apache.log4j.Logger.respond_to?(:__persistent__)
