
module Log4jruby
  class Logger
    BLANK_CALLER = ['', '', '']
    MDC = Java::org.apache.log4j.MDC

    attr_accessor :trace

    class << self
      attr_accessor :trace

      def[](name)
        name = name.nil? ? 'jruby' : "jruby.#{name.gsub('::', '.')}"
       
        log4j = Java::org.apache.log4j.Logger.getLogger(name)
        log4jruby = log4j.instance_variable_get(:@log4jruby)
        
        unless log4jruby
          log4jruby = new(log4j)
        end
        
        log4jruby
      end
      
      def get(name, values = {})
        logger = self[name]
        logger.attributes = values
        logger
      end
      
      def tracing?
        trace == true
      end

      def root
        log4j = Java::org.apache.log4j.Logger.getLogger('jruby')
        log4jruby = log4j.instance_variable_get(:@log4jruby)
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

    def debug(object = nil, &block)
      if @logger.isDebugEnabled
        with_context(:debug, object, &block)
      end
    end

    def info(object = nil, &block)
      if @logger.isInfoEnabled
        with_context(:info, object, &block)
      end
    end

    def warn(object = nil, &block)
      if @logger.isWarnEnabled
        with_context(:warn, object, &block)
      end
    end

    def error(object = nil, &block)
      with_context(:error, object, &block)
    end

    def log_error(msg, error)
      with_context(:error, msg, error)
    end

    def fatal(object = nil, &block)
      with_context(:fatal, object, &block)
    end

    def log_fatal(msg, error)
      with_context(:fatal, msg, error)
    end

    def log4j_logger
      @logger
    end

    def tracing?
      trace.nil? ? Logger.tracing? : (trace == true)
    end

    private

    def initialize(logger, values = {})
      @logger = logger  
      @logger.instance_variable_set(:@log4jruby, self)
      self.attributes = values
    end
    
    def with_context(method, object, exception = nil, &block)
      parsed_caller = tracing? ? parse_caller(caller(2).first) : BLANK_CALLER

      MDC.put("fileName", parsed_caller[0].to_s)
      MDC.put("lineNumber", parsed_caller[1].to_s)
      MDC.put("methodName", parsed_caller.last.to_s)

      begin
        msg, throwable = log4j_args(object, exception, &block)

        @logger.send(method, msg, throwable)
      ensure
        MDC.remove("fileName")
        MDC.remove("lineNumber")
        MDC.remove("methodName")
      end
    end

    def log4j_args(object, exception, &block)
      msg = ''

      if exception
        msg << object.to_s
      else
        exception = block_given? ? yield : object
      end

      if exception.is_a?(NativeException)
        exception = exception.cause
      elsif exception.is_a?(::Exception)
        if msg.empty?
          msg = "#{exception}\n  " + exception.backtrace.join("\n  ")
        else
          msg << "\n#{exception}\n  " + exception.backtrace.join("\n  ")
        end
        exception = nil
      elsif !exception.is_a?(java.lang.Throwable)
        msg << exception.to_s
        exception = nil
      end

      [msg, exception]
    end

    def parse_caller(at)
      if /^(.+?):(\d+)(?::in `(.*)')?/ =~ at
        file = Regexp.last_match[1]
        line = Regexp.last_match[2].to_i
        method = Regexp.last_match[3]
        [file, line, method]
      end
    end

  end
end
