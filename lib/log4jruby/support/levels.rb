# frozen_string_literal: true

require 'logger'

module Log4jruby
  module Support
    # Utility methods for dealing with log levels
    class Levels
      LOG4J_LEVELS = {
        Java::org.apache.logging.log4j.Level::DEBUG => ::Logger::DEBUG,
        Java::org.apache.logging.log4j.Level::INFO => ::Logger::INFO,
        Java::org.apache.logging.log4j.Level::WARN => ::Logger::WARN,
        Java::org.apache.logging.log4j.Level::ERROR => ::Logger::ERROR,
        Java::org.apache.logging.log4j.Level::FATAL => ::Logger::FATAL
      }.freeze

      class << self
        def ruby_logger_level(log4j_level)
          LOG4J_LEVELS[log4j_level]
        end

        # rubocop:disable Metrics/AbcSize
        def log4j_level(ruby_logger_level)
          case ruby_logger_level
          when :debug, ::Logger::DEBUG
            Java::org.apache.logging.log4j.Level::DEBUG
          when :info, ::Logger::INFO
            Java::org.apache.logging.log4j.Level::INFO
          when :warn, ::Logger::WARN
            Java::org.apache.logging.log4j.Level::WARN
          when :error, ::Logger::ERROR
            Java::org.apache.logging.log4j.Level::ERROR
          when :fatal, ::Logger::FATAL
            Java::org.apache.logging.log4j.Level::FATAL
          when nil
            #noop
          else
            raise NotImplementedError
          end
        end
        # rubocop:enable Metrics/AbcSize
      end
    end
  end
end
