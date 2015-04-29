require 'log4jruby/support/log4j_args'

require 'logger'

module Log4jruby
  
  # Author::    Lenny Marks
  #
  # Wrapper around org.apache.log4j.Logger with interface similar to standard ruby Logger.
  #
  # * Ruby and Java exceptions are logged with backtraces.
  # * fileName, lineNumber, methodName available to appender layouts via MDC variables(e.g. %X{lineNumber}) 
  class Logger
    BLANK_CALLER = ['', '', ''] #:nodoc:

    LOG4J_LEVELS = {
        Java::org.apache.log4j.Level::DEBUG => ::Logger::DEBUG,
        Java::org.apache.log4j.Level::INFO => ::Logger::INFO,
        Java::org.apache.log4j.Level::WARN => ::Logger::WARN,
        Java::org.apache.log4j.Level::ERROR => ::Logger::ERROR,
        Java::org.apache.log4j.Level::FATAL => ::Logger::FATAL,
    }

    # turn tracing on to make fileName, lineNumber, and methodName available to 
    # appender layout through MDC(ie. %X{fileName} %X{lineNumber} %X{methodName})
    attr_accessor :tracing

    class << self
      # get Logger for name
      def[](name)
        name = name.nil? ? 'jruby' : "jruby.#{name.gsub('::', '.')}"
        log4j = Java::org.apache.log4j.Logger.getLogger(name)
        fetch_logger(log4j, new(log4j))
      end
      
      # same as [] but accepts attributes
      def get(name, values = {})
        logger = self[name]
        logger.attributes = values
        logger
      end
      
      # Return root Logger(i.e. jruby)
      def root
        log4j = Java::org.apache.log4j.Logger.getLogger('jruby')
        fetch_logger(log4j, new(log4j))
      end

      private

      def fetch_logger(log4j_logger, default)
        @logger_mapping.putIfAbsent(log4j_logger.getName, default) || @logger_mapping.get(log4j_logger.getName)
      end

      def init_store
        @logger_mapping = Java::java.util.concurrent.ConcurrentHashMap.new
      end
    end
    
    def attributes=(values)
      if values
        values.each_pair do |k, v|
          setter = "#{k}="
          send(setter, v) if respond_to?(setter)
        end
      end
    end
    
    # Shortcut for setting log levels. (:debug, :info, :warn, :error, :fatal)
    def level=(level)
      @logger.level = case level
      when :debug, ::Logger::DEBUG
        Java::org.apache.log4j.Level::DEBUG
      when :info, ::Logger::INFO
        Java::org.apache.log4j.Level::INFO
      when :warn, ::Logger::WARN
        Java::org.apache.log4j.Level::WARN
      when :error, ::Logger::ERROR
        Java::org.apache.log4j.Level::ERROR
      when :fatal, ::Logger::FATAL
        Java::org.apache.log4j.Level::FATAL
      else
        raise NotImplementedError
      end
    end
    
    def level
      LOG4J_LEVELS[@logger.effectiveLevel]
    end
    
    def flush
      #rails compatability
    end

    def debug(object = nil, &block)
      if debug?
        send_to_log4j(:debug, object, nil, &block)
      end
    end

    def info(object = nil, &block)
      if info?
        send_to_log4j(:info, object, nil, &block)
      end
    end

    def warn(object = nil, &block)
      if warn?
        send_to_log4j(:warn, object, nil, &block)
      end
    end

    def error(object = nil, &block)
      send_to_log4j(:error, object, nil, &block)
    end

    def log_error(msg, error)
      send_to_log4j(:error, msg, error)
    end

    def fatal(object = nil, &block)
      send_to_log4j(:fatal, object, nil, &block)
    end

    def log_fatal(msg, error)
      send_to_log4j(:fatal, msg, error)
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
      if tracing.nil?
        if parent == Logger.root
          Logger.root.tracing == true
        else
          parent.tracing?
        end
      else
        tracing == true
      end
    end
    
    def parent
      fetch_logger(log4j_logger.parent, Logger.root)
    end
    
    private

    def initialize(logger) # :nodoc:
      @logger = logger
    end

    def with_context # :nodoc:
      file_line_method = tracing? ? parse_caller(caller(3).first) : BLANK_CALLER

      mdc.put('fileName', file_line_method[0])
      mdc.put('lineNumber', file_line_method[1])
      mdc.put('methodName', file_line_method[2].to_s)

      begin
        yield
      ensure
        mdc.remove('fileName')
        mdc.remove('lineNumber')
        mdc.remove('methodName')
      end
    end

    def send_to_log4j(level, object, error, &block)
      msg, throwable = Support::Log4jArgs.convert(object, error, &block)
      with_context do
        @logger.send(level, msg, throwable)
      end
    end

    def parse_caller(at) # :nodoc:
      at.match(/^(.+?):(\d+)(?::in `(.*)')?/).captures
    end
    
    def mdc
      Java::org.apache.log4j.MDC 
    end
  end
end

Log4jruby::Logger.send(:init_store) #Avoid lazy-initialization thread-safety issues on logger_mapping