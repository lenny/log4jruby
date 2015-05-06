module Log4jruby
  module Support
  end
end

require 'log4jruby/support/bootstrap'
require 'log4jruby/logger'
require 'log4jruby/logger_for_class'

Object.class_eval do
  class << self
    def enable_logger
      send(:include, Log4jruby::LoggerForClass)
    end
  end
end
