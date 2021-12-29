require File.dirname(__FILE__) + '/setup'

require 'log4jruby'

logger = Log4jruby::Logger.get('test', :tracing => true, :level => :debug)

# In addition to the outer ruby exception with its backtrace,
# this should also include nested exceptions

def foo
  bar
rescue
  raise 'raised from foo'
end

def bar
  baz
rescue
  raise 'raised from bar'
end

def baz
  raise 'raised from baz'
end

foo
