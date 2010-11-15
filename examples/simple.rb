require File.dirname(__FILE__) + '/setup'

require 'log4jruby'

logger = Log4jruby::Logger.get('test', :tracing => true, :level => :debug)

logger.debug("hello world")

class MyClass
  def initialize
    @logger = Log4jruby::Logger.get(self.class.name, :level => :debug, :tracing => true)
  end
  
  def foo
    @logger.debug("hello from foo")
    raise "foo error"
  end

  def bar
    @logger.debug("hello from bar")
    foo
  end

  def baz
    @logger.debug("hello from baz")
    begin
      bar
    rescue => e
      @logger.error(e)
    end
  end
end

o = MyClass.new
o.baz

logger.debug("changing log level for MyClass to ERROR")

myclass_logger = Log4jruby::Logger['MyClass']
myclass_logger.level = :error

logger.debug("calling baz again")
o.baz

