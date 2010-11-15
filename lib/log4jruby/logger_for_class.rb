require 'log4jruby'

module Log4jruby
  
  # Gives class its own Logger and makes it available via class and instance method. 
  module LoggerForClass
    
    def self.included(klass)
      def klass.logger
        @logger ||= Logger.get(name)
      end
    end

    def logger
      self.class.logger
    end
  end
end