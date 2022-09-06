# log4jruby Changelog

## v3.0.0.rc1

* JRuby 9.3.x/Ruby 2.6 support - Ruby >= 2.6.8 now required
* Updated for Log4j2
  Note:
  > In Log4j 1.x the Logger Hierarchy was maintained through a relationship between Loggers. 
    In Log4j 2 this relationship no longer exists. Instead, the hierarchy is maintained in the 
    relationship between LoggerConfig objects. 
  from the [Log4j 2 Architecture page](https://logging.apache.org/log4j/2.x/manual/architecture.html)
* Formatters and logging output
   * Consistent treatment for Ruby and Java exceptions - Previously, ruby exception backtraces were
  not passed directly to Log4j. Instead a backtrace string was generated and included in the exception
  message. JRuby now handles mapping Ruby exceptions/errors to Java exceptions that can be
  passed directly as the `Throwable` parameter to Log4j.
   * Formatter parity with the standard Ruby Logger - Custom formatters
     (see [formatter in the
      Ruby Logger docs](https://ruby-doc.org/stdlib-2.7.0/libdoc/logger/rdoc/Logger.html)
 now receive the same arguments from Log4Jruby as they would from the standard Ruby Logger
 given the same logging invocation.
   * Default formatter - The [standard Ruby Logger](https://ruby-doc.org/stdlib-2.7.0/libdoc/logger/rdoc/Logger.html)
     uses a default formatter that outputs backtraces (without nested causes). Log4jruby now uses
     a default formatter that outputs `progname` and `msg` only. Severity and timestamp are output
     according to your Log4j configuration. E.g. [PatternLayout](https://logging.apache.org/log4j/2.x/manual/layouts.html)
   * The output of the `formatter` is passed as the `message` parameter of the 
     [Log4j log methods](https://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/Category.html) 
* Nested ruby exceptions are now handled - E.g. The backtrace output from `logger.error { ruby_error_with_nested_causes }` will
  include nested causes for both Ruby and Java exceptions.
* Log4jruby no longer utilizes deprecated [JRuby Persistence](https://github.com/jruby/jruby/wiki/Persistence)
* Development
   * Rubocop introduced and violations squashed
   * Mavenized log4j development dependency, added `dev:java_deps` Rake task, and removed bundled log4j jar
   
## v2.0.1

* JRuby 9K compatibility - https://github.com/lenny/log4jruby/issues/14

## v2.0.0

* Documentation additions, corrections.

## v2.0.0.rc3

* Add Logger#silence for ActiveSupport::Logger compatibility - https://github.com/lenny/log4jruby/pull/11

## v2.0.0.rc2

* Internal implementation changes - https://github.com/lenny/log4jruby/pull/8

## v2.0.0.rc1

* ```Log4jruby::Rails``` has been removed - Rails apps seem better off configuring
  logging using standard/vanilla means to more easily facilitate usage of TaggedLogging, etc..
  ```

   e.g.
   config.logger = ActiveSupport::TaggedLogging.new(Log4jruby::Logger.get('appname'))
  ```
* Internal support classes moved to Log4jruby::Support
* specs updated to Rspec 3 syntax
* Deadlock/thread-safety issues https://github.com/lenny/log4jruby/issues/2
* Support for formatters (Rails 4 compatibility - https://github.com/lenny/log4jruby/issues/1)
* Performance optimizations (https://github.com/lenny/log4jruby/commit/e9a2a2ac347de38431e243b062602c5055163f2c)

## v1.0.0 - Same as v1.0.0.rc1

## v1.0.0.rc1

* setting level now accepts ::Logger constants and symbols
* Logger#level now returns ::Logger constant values instead of Log4j log level classes.
 Note, you can still get at log4j constants via #log4_logger.level
* Logger#level now returns effective log level (i.e. parent logger's level when not explicitly set)
