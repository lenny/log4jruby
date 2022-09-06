# frozen_string_literal: true

module Log4jruby
  # Support namespace
  module Support
  end
end

require 'log4jruby/logger'
require 'log4jruby/logger_for_class'

Object.class_eval do
  class << self
    def enable_logger
      send(:include, Log4jruby::LoggerForClass)
    end
  end
end
