require File.dirname(__FILE__) + '/setup'

require 'log4jruby'

logger = Log4jruby::Logger.get('test', :tracing => true, :level => :debug)

logger.debug("hello world")

class MyClass
  attr_reader :logger
  
  def initialize
    @logger = Log4jruby::Logger.get(self.class.name, :level => :debug, :tracing => true)
  end

  def foo
    logger.debug("hello from foo")
    bar
  rescue => e
    logger.error(e)
  end

  def bar
    logger.debug("hello from bar")
    baz
  end

  def baz
    logger.debug("hello from baz")
    raise "error from baz"
  end
end

o = MyClass.new
o.foo

logger.debug("changing log level for MyClass to ERROR")

Log4jruby::Logger.get('MyClass', :level => :error)

logger.debug("calling foo again")
o.foo

