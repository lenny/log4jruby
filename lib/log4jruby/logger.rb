# frozen_string_literal: true

require 'log4jruby/support/log4j_args'
require 'log4jruby/support/levels'
require 'log4jruby/support/location'
require 'log4jruby/support/log_manager'
require 'log4jruby/support/formatter'
require 'log4jruby/support/legacy_shim_formatter'
require 'log4jruby/support/jruby_version'

require 'logger'

module Log4jruby
  # Author::    Lenny Marks
  #
  # Wrapper around org.apache.logging.log4j.Logger with interface similar to standard ruby Logger.
  #
  # * Ruby and Java exceptions are logged with backtraces.
  # * fileName, lineNumber, methodName available to appender layouts via
  # * MDC variables(e.g. %X{lineNumber})
  class Logger
    Support::LogManager.configure(logger_class: self)

    class << self
      # get Logger for name
      def[](name)
        name = name.nil? ? root.name : "#{root.name}.#{name.gsub('::', '.')}"
        Support::LogManager.get_or_create(name)
      end

      # same as [] but accepts attributes
      def get(name, values = {})
        logger = self[name]
        logger.attributes = values
        logger
      end

      # Return root Logger(i.e. jruby)
      def root
        Support::LogManager.root
      end
    end

    def attributes=(values)
      values&.each_pair do |k, v|
        setter = "#{k}="
        send(setter, v) if respond_to?(setter)
      end
    end

    def name
      log4j_logger.name
    end

    # Shortcut for setting log levels. (:debug, :info, :warn, :error, :fatal)
    def level=(level)
      @log4j_logger.level = Support::Levels.log4j_level(level)
    end

    def level
      Support::Levels.ruby_logger_level(@log4j_logger.level)
    end

    def flush
      # rails compatability
    end

    def debug(object = nil, &block)
      send_to_log4j(:debug, object, &block) if debug?
    end

    def info(object = nil, &block)
      send_to_log4j(:info, object, &block) if info?
    end

    def warn(object = nil, &block)
      send_to_log4j(:warn, object, &block) if warn?
    end

    def error(object = nil, &block)
      send_to_log4j(:error, object, &block)
    end

    def log_error(msg, error)
      send_to_log4j(:error, msg) { error }
    end

    def fatal(object = nil, &block)
      send_to_log4j(:fatal, object, &block)
    end

    def log_fatal(msg, error)
      send_to_log4j(:fatal, msg) { error }
    end

    # return org.apache.logging.log4j.Logger instance backing this Logger
    attr_reader :log4j_logger

    def debug?
      @log4j_logger.isEnabled(Java::org.apache.logging.log4j.Level::DEBUG)
    end

    def info?
      @log4j_logger.isEnabled(Java::org.apache.logging.log4j.Level::INFO)
    end

    def warn?
      @log4j_logger.isEnabled(Java::org.apache.logging.log4j.Level::WARN)
    end

    def tracing?
      return @tracing if defined?(@tracing)

      @tracing = self == Logger.root ? false : parent.tracing?
    end
    alias tracing tracing?

    # turn tracing on to make fileName, lineNumber, and methodName available to
    # appender layout through MDC(ie. %X{fileName} %X{lineNumber} %X{methodName})
    def tracing=(bool)
      @tracing = !!bool
    end

    def formatter
      return @formatter if defined?(@formatter)

      @formatter = if self == Logger.root
                     new_default_formatter
                   else
                     parent.formatter
                   end
    end

    # @param [::Logger::Formatter]
    attr_writer :formatter

    def parent
      Support::LogManager.parent(log4j_logger.name)
    end

    # Compatibility with ActiveSupport::Logger
    # needed to use a Log4jruby::Logger as an ActiveRecord::Base.logger
    def silence(temporary_level = ::Logger::ERROR, &blk)
      with_level(temporary_level, &blk)
    end

    def with_level(temporary_level = ::Logger::ERROR)
      old_logger_level = level
      self.level = temporary_level
      yield self
    ensure
      self.level = old_logger_level
    end

    def initialize(logger) # :nodoc:
      @log4j_logger = logger
    end

    private

    def send_to_log4j(level, object, &block)
      progname, msg, throwable = Support::Log4jArgs.convert(object, &block)
      if (f = formatter)
        msg = f.call(level, Time.now, progname, msg)
      end
      if tracing?
        Support::Location.with_location do
          @log4j_logger.send(level, msg, throwable)
        end
      else
        @log4j_logger.send(level, msg, throwable)
      end
    end

    def new_default_formatter
      Support::JrubyVersion.native_ruby_stacktraces_supported? ? Support::Formatter.new :
        Support::LegacyShimFormatter.new
    end
  end
end
