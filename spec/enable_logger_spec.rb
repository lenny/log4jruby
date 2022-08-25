# frozen_string_literal: true

require 'spec_helper'

require 'log4jruby'

describe '.enable_logger injects a logger', log_capture: true do
  prepend_before do
    Log4jruby::Support::LogManager.reset
  end

  let(:klass) do
    Class.new do
      enable_logger

      class << self
        def name
          'Klass'
        end

        def echo(str)
          logger.debug(str)
        end
      end

      def echo(str)
        logger.debug(str)
      end
    end
  end

  specify 'lo4j logger is named for class' do
    expect(klass.logger.log4j_logger.name)
      .to include('Klass')
  end

  specify 'logger is available to class methods' do
    klass.echo('foo')
    expect(log_capture).to include('foo')
  end

  specify 'logger is available to instance methods' do
    # Java::org.apache.logging.log4j.LogManager.rootLogger.error("test")
    # raise EnableLoggerSpec::LogEnabledClass.new.send(:logger).log4j_logger.getAppenders.inspect
    # raise  Java::org.apache.logging.log4j.LogManager.rootLogger.level.toString
    klass.new.echo('foo')
    expect(log_capture).to include('foo')
  end

  specify 'subclasses get distinct loggers' do
    subclass = Class.new(klass) do
      def self.name
        'SubClass'
      end
    end
    expect(subclass.logger.name).to eq('jruby.SubClass')
  end
end
