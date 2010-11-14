require 'log4jruby'

module Log4jruby
  module LoggerForClass
    
    def self.included(klass) # :nodoc:
      def klass.logger
        @logger ||= Logger.get(name)
      end
    end

    def logger
      self.class.logger
    end
  end
end