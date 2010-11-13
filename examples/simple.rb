require File.dirname(__FILE__) + '/setup'

require 'log4jruby'

logger = Log4jruby::Logger.new('test', :trace => true, :level => :debug)

logger.debug("hello world")

class MyClass
  def initialize
    @logger = Log4jruby::Logger.new(self.class.name, :level => :debug, :trace => true)
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

logger.debug("changing log level for MyClass to ERROR directly through log4j")

log4j_logger = Java::org.apache.log4j.Logger.getLogger('jruby.MyClass')
log4j_logger.level = Java::org.apache.log4j.Level::ERROR

logger.debug("calling baz again")
o.baz

