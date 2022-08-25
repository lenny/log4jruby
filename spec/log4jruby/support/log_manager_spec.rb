# frozen_string_literal: true

require 'spec_helper'

require 'log4jruby/support/log_manager'

LoggerClass = Class.new do
  attr_reader :log4j_logger

  def initialize(log4j_logger)
    @log4j_logger = log4j_logger
  end

  def name
    log4j_logger.name
  end
end

LogManager = Log4jruby::Support::LogManager

Log4jruby::Support::LogManager.configure(logger_class: LoggerClass)

describe 'Log4jruby::Support::LogManager' do
  describe '.get_or_create(name)' do
    it 'creates logger when none already exists' do
      expect(LogManager.get_or_create('foo').name).to eq('foo')
    end

    it 'returns previously created logger when present' do
      expect(LogManager.get_or_create('foo'))
        .to equal(LogManager.get_or_create('foo'))
    end
  end

  describe '.parent' do
    it 'returns root logger without more direct parent' do
      expect(LogManager.parent('foo')).to equal(LogManager.root)
    end

    it 'returns closest parent' do
      LogManager.get_or_create('Foo')
      LogManager.get_or_create('Foo.Bar')
      expect(LogManager.parent('Foo.Bar.Baz').name).to eq('Foo.Bar')
      expect(LogManager.parent('Foo.Bar').name).to eq('Foo')
      expect(LogManager.parent('Foo')).to equal(LogManager.root)
    end
  end
end
