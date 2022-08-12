# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/setup"

require 'log4jruby'

logger = Log4jruby::Logger.root
logger.level = :debug

module MyModule
  # Example class A
  class A
    enable_logger

    class << self
      def my_class_method
        logger.info('hello from class method')
      end
    end

    def my_method
      logger.info('hello from instance method')
    end
  end

  # Example class B
  class B < A
  end
end

MyModule::A.logger.attributes = { tracing: true, level: :info }

MyModule::A.my_class_method
MyModule::A.new.my_method

logger.debug("Log4j Logger name for MyModule::A - #{MyModule::A.logger.log4j_logger.name}")
logger.debug("Log4j Logger name for MyModule::B - #{MyModule::B.logger.log4j_logger.name}")
