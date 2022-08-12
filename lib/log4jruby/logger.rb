# frozen_string_literal: true

require 'log4jruby/support/log4j_args'
require 'log4jruby/support/levels'
require 'log4jruby/support/mdc'

require 'logger'

module Log4jruby
  # Author::    Lenny Marks
  #
  # Wrapper around org.apache.log4j.Logger with interface similar to standard ruby Logger.
  #
  # * Ruby and Java exceptions are logged with backtraces.
  # * fileName, lineNumber, methodName available to appender layouts via
  # * MDC variables(e.g. %X{lineNumber})
  class Logger
    class << self
      # get Logger for name
      def[](name)
        name = name.nil? ? 'jruby' : "jruby.#{name.gsub('::', '.')}"
        fetch_logger(Java::org.apache.log4j.Logger.getLogger(name))
      end

      # same as [] but accepts attributes
      def get(name, values = {})
        logger = self[name]
        logger.attributes = values
        logger
      end

      # Return root Logger(i.e. jruby)
      def root
        fetch_logger(Java::org.apache.log4j.Logger.getLogger('jruby'))
      end

      def reset # :nodoc:
        Java::org.apache.log4j.LogManager.getCurrentLoggers.each do |l|
          l.ruby_logger = nil
        end
      end

      private

      def fetch_logger(log4j_logger)
        Java::org.apache.log4j.Logger.getLogger(log4j_logger.getName).ruby_logger
      end
    end

    def attributes=(values)
      values&.each_pair do |k, v|
        setter = "#{k}="
        send(setter, v) if respond_to?(setter)
      end
    end

    # Shortcut for setting log levels. (:debug, :info, :warn, :error, :fatal)
    def level=(level)
      @logger.level = Support::Levels.log4j_level(level)
    end

    def level
      Support::Levels.ruby_logger_level(@logger.effectiveLevel)
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

    # return org.apache.log4j.Logger instance backing this Logger
    def log4j_logger
      @logger
    end

    def debug?
      @logger.isEnabledFor(Java::org.apache.log4j.Priority::DEBUG)
    end

    def info?
      @logger.isEnabledFor(Java::org.apache.log4j.Priority::INFO)
    end

    def warn?
      @logger.isEnabledFor(Java::org.apache.log4j.Priority::WARN)
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
                     ->(_severity, _datetime, progname, msg) { "-- #{progname}: #{msg}" }
                   else
                     parent.formatter
                   end
    end

    # @param [::Logger::Formatter]
    attr_writer :formatter

    def parent
      fetch_logger(log4j_logger.parent)
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

    private

    def initialize(logger) # :nodoc:
      @logger = logger
    end

    def send_to_log4j(level, object, &block)
      progname, msg, throwable = Support::Log4jArgs.convert(object, &block)
      if (f = formatter)
        msg = f.call(level, Time.now, progname, msg)
      end
      if tracing?
        Support::Mdc.with_context do
          @logger.send(level, msg, throwable)
        end
      else
        @logger.send(level, msg, throwable)
      end
    end

    def fetch_logger(log4j_logger)
      self.class.send(:fetch_logger, log4j_logger)
    end
  end
end
