require 'log4jruby/log4j_args'

module Log4jruby
  
  # Author::    Lenny Marks
  #
  # Wrapper around org.apache.log4j.Logger with interface similar to standard ruby Logger.
  #
  # * Ruby and Java exceptions are logged with backtraces.
  # * fileName, lineNumber, methodName available to appender layouts via MDC variables(e.g. %X{lineNumber}) 
  class Logger
    BLANK_CALLER = ['', '', ''] #:nodoc:
    MDC = Java::org.apache.log4j.MDC 
    
    # turn tracing on to make fileName, lineNumber, and methodName available to 
    # appender layout through MDC(ie. %X{fileName} %X{lineNumber} %X{methodName})
    attr_accessor :tracing

    class << self
      def logger_mapping
        @logger_mapping ||= {}
      end
      
      # get Logger for name
      def[](name)
        name = name.nil? ? 'jruby' : "jruby.#{name.gsub('::', '.')}"
       
        log4j = Java::org.apache.log4j.Logger.getLogger(name)
        log4jruby = logger_mapping[log4j]
        
        unless log4jruby
          log4jruby = new(log4j)
        end
        
        log4jruby
      end
      
      # same as [] but acceptions attributes
      def get(name, values = {})
        logger = self[name]
        logger.attributes = values
        logger
      end
      
      # Return root Logger(i.e. jruby)
      def root
        log4j = Java::org.apache.log4j.Logger.getLogger('jruby')
        
        log4jruby = logger_mapping[log4j]
        unless log4jruby
          log4jruby = new(log4j)
        end
        log4jruby
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
    
    # Shortcut for setting log levels. (:debug, :info, :warn, :error)
    def level=(level)
      @logger.level = case level
      when :debug
        then Java::org.apache.log4j.Level::DEBUG
      when :info
        then Java::org.apache.log4j.Level::INFO
      when :warn
        then Java::org.apache.log4j.Level::WARN
      when :error
        then Java::org.apache.log4j.Level::ERROR
      else
        raise NotImplementedError
      end
    end
    
    def level
      @logger.level
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
      @logger.isDebugEnabled
    end
    
    def info?
      @logger.isInfoEnabled
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
      logger_mapping[log4j_logger.parent] || Logger.root
    end
    
    private
    
    def logger_mapping
      Logger.logger_mapping
    end

    def initialize(logger, values = {}) # :nodoc:
      @logger = logger  
     
      Logger.logger_mapping[@logger] = self
      
      self.attributes = values
    end
    
    def with_context # :nodoc:
      file_line_method = tracing? ? parse_caller(caller(3).first) : BLANK_CALLER

      MDC.put("fileName", file_line_method[0])
      MDC.put("lineNumber", file_line_method[1])
      MDC.put("methodName", file_line_method[2].to_s)

      begin
        yield
      ensure
        MDC.remove("fileName")
        MDC.remove("lineNumber")
        MDC.remove("methodName")
      end
    end

    def send_to_log4j(level, object, error, &block)
      msg, throwable = Log4jArgs.convert(object, error, &block)
      with_context do
        @logger.send(level, msg, throwable)
      end
    end

    def parse_caller(at) # :nodoc:
      at.match(/^(.+?):(\d+)(?::in `(.*)')?/).captures
    end

  end
end
