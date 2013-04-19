require 'spec_helper'

require 'log4jruby'

describe '.enable_logger injects a logger', :log_capture => true do
  class LogEnabledClass
    enable_logger

    def echo(s)
      logger.debug(s)
    end
  end

  specify 'lo4j logger is named for class' do
    LogEnabledClass.logger.log4j_logger.name.should include('LogEnabledClass')
  end

  specify 'logger is available to instance' do
    LogEnabledClass.new.echo('foo')
    log_capture.should include('foo')
  end
end