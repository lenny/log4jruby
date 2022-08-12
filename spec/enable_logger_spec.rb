# frozen_string_literal: true

require 'spec_helper'

require 'log4jruby'

module EnableLoggerSpec
  class LogEnabledClass
    enable_logger

    def echo(str)
      logger.debug(str)
    end
  end
end

describe '.enable_logger injects a logger', log_capture: true do
  specify 'lo4j logger is named for class' do
    expect(EnableLoggerSpec::LogEnabledClass.logger.log4j_logger.name)
      .to include('LogEnabledClass')
  end

  specify 'logger is available to instance' do
    EnableLoggerSpec::LogEnabledClass.new.echo('foo')
    expect(log_capture).to include('foo')
  end
end
