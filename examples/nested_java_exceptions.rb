require File.dirname(__FILE__) + '/setup'

require 'log4jruby'
java_import 'examples.NestedExceptions'

logger = Log4jruby::Logger.get('test', :tracing => true, :level => :debug)

# In addition to the outer ruby exception with its backtrace,
# this should also pass the wrapped Java exception to log4j
# so the full java stacktrace is logged(i.e. nested exceptions included)
begin
  NestedExceptions.new
rescue => e
  logger.error(e)
end