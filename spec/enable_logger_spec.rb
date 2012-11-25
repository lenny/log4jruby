require 'spec_helper'

require 'log4jruby'

describe '.enable_logger injects a logger', :log_capture => true do
  specify 'lo4j logger is named for class' do
    Log4JLoggerIsNamedForClass = Class.new do
      enable_logger
      def initialize
        logger.debug(logger.log4j_logger.name)
      end
    end
    Log4JLoggerIsNamedForClass.new
    log_capture.should include('Log4JLoggerIsNamedForClass')
  end
end