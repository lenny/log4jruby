require File.dirname(__FILE__) + '/setup'

require 'log4jruby'
require 'log4jruby/logging'

class A
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

class B < A
end

class C < B
end

A.logger.trace = true
A.logger.level = :info

A.my_class_method
A.new.my_method

puts A.logger.log4j_logger.name
puts B.logger.log4j_logger.name
puts C.logger.log4j_logger.name





