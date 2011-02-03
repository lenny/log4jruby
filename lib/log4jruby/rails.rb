require 'log4jruby'

module Log4jruby
  
  # Configure Rails logging from a config/initializers file
  # 
  # Setting up log4j using config.logger from within the Rails initialization
  # process may not be possible if the CLASSPATH has not yet been setup.
  # This class can be used to configure the logging from within a config/initializers/
  # file.
  #
  # ex.
  #   require 'log4jruby/rails'
  #   Log4jruby::Rails.configure do |c|
  #     c.logger_name = 'MyApp'
  #   end
  # 
  # @attr [String] logger_name     Default is 'Rails'
  # @attr [String] tracing         Defaults to false in 'production' or true otherwise
  # 
  #
  class Rails
    attr_accessor :logger_name, :tracing

    def initialize #:nodoc:
      @logger_name = 'Rails'
      @tracing = (::Rails.env != 'production')

      yield(self)
    end

    class << self
      
      # Sets rails Base loggers(e.g. ActionController::Base, ActiveRecord::Base, etc)
      # 
      # @yield [config] Block to customize configuration
      # @yeildparam [Rails] config 
      def configure(&block)
        config = new(&block)

        Logger.root.tracing = config.tracing

        logger = Log4jruby::Logger.get(config.logger_name)

        set_logger('ActionController', logger)
        set_logger('ActiveRecord', logger)
        set_logger('ActiveResource', logger)
        set_logger('ActionMailer', logger)
      end

      private
      
      def set_logger(framework, logger)
        begin
          Kernel.const_get(framework).const_get('Base').logger = logger
        rescue
          logger.info "Skipping logger setup for #{framework}"
        end
      end
    end
  end
end
