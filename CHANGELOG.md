# log4jruby Changelog

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
