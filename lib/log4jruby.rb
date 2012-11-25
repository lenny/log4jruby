require 'log4jruby/logger'
require 'log4jruby/logger_for_class'

module Log4jruby

end

Object.class_eval do
  class << self
    def enable_logger
      send(:include, Log4jruby::LoggerForClass)
    end
  end
end