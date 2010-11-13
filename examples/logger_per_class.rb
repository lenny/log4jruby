require File.dirname(__FILE__) + '/setup'

require 'log4jruby'
require 'log4jruby/logging'

class MyClass
  include Log4jruby::Logging
  
  class << self
    def my_class_method
      logger.info("hello from class method")
    end
  end
  
  def my_method
    logger.info("hello from instance method")
  end
end

MyClass.logger.trace = true
MyClass.logger.level = :info

MyClass.my_class_method
MyClass.new.my_method



