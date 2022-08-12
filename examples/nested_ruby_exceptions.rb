# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/setup"

require 'log4jruby'

logger = Log4jruby::Logger.get('test', tracing: true, level: :debug)

# In addition to the outer ruby exception with its backtrace,
# this should also include nested exceptions

def foo
  bar
rescue StandardError
  raise 'raised from foo'
end

def bar
  baz
rescue StandardError
  raise 'raised from bar'
end

def baz
  raise 'raised from baz'
end

begin
  foo
rescue StandardError => e
  logger.error(e)
end
