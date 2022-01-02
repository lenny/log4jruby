# Log4jruby

`Log4jruby` provides an interface mostly compatible with the standard ruby [Logger](http://ruby-doc.org/core/classes/Logger.html) but backed by  [Log4j](http://logging.apache.org/log4j/1.2/apidocs/index.html). This makes the granular log output configuration, stacktrace output, and other facilities of `log4j` available to Java and Ruby code alike. For projects that extend/integrate Java already dependent on `log4j`, it allows log configuration for Java and Ruby code in one spot.

_Note*_ Currently log4j 1.2 only

* Automatic stacktrace output (including nested causes) for logged exceptions
* Configure Java and Ruby logging together (e.g a single `log4j.properties` file) and gain `log4j` features such as runtime output targets for Ruby code.
* Supports inclusion of filename, line number, and method name in log messages via [MDC](http://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/MDC.html). Note: `tracing` must be enabled.
* High level support for class based logging via the `enable_logger` macro. 
* Compatible with the `Rails` logging.


### Usage and examples

Enable class level logging via `enable_logger`

```ruby
 require 'log4jruby'

 class MyClass
   enable_logger

   class << self
     def my_class_method
       logger.info("hello from class method")
     end
   end

   def my_method
     logger.info("hello from instance method")
   end
 end
```

Custom logger name

```ruby
logger = Log4jruby::Logger.get('my.logger')
logger.debug('something')
```

Log4jruby logger names are prefixed with `.jruby`.

e.g. `log4j.properties`

```ini
 ...
 log4j.logger.jruby=info,Console
 log4j.logger.jruby.MyClass=debug
 log4j.logger.jruby.my.logger=error
```

Inclusion of filename, line number, and method name in log messages via [MDC](http://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/MDC.html)

e.g.

```ini
log4j.appender.Ruby.layout.ConversionPattern=%5p %.50X{fileName} %X{methodName}:%X{lineNumber} - %m%n
```

enable tracing globally

```
Log4jruby::Logger.root.tracing = true
```

or for specific logger

```
Log4jruby::Logger.get('MyClass', tracing: true)
```

produces log statements like: 

```
DEBUG jruby.MyClass foo:17 - hello from foo
```

Exceptions are logged with backtraces

```bash
$ ruby ./examples/nested_ruby_exceptions.rb 
RuntimeError: raised from foo
     foo at ./examples/nested_ruby_exceptions.rb:13
  <main> at ./examples/nested_ruby_exceptions.rb:26
RuntimeError: raised from bar
     bar at ./examples/nested_ruby_exceptions.rb:19
     foo at ./examples/nested_ruby_exceptions.rb:11
  <main> at ./examples/nested_ruby_exceptions.rb:26
RuntimeError: raised from baz
     baz at ./examples/nested_ruby_exceptions.rb:23
     bar at ./examples/nested_ruby_exceptions.rb:17
     foo at ./examples/nested_ruby_exceptions.rb:11
  <main> at ./examples/nested_ruby_exceptions.rb:26
```


```
logger.warn(exception)
```

```
logger.warn { exception }
```

Some [Log4j Logger](https://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/Logger.html) compatible signatures addded.

```
logger.log_error(msg, exception)
```

See more in [log4jruby/examples](examples).


### Configuration

Configuring log4j is left to the client via the [standard log4j configuration process](https://logging.apache.org/log4j/1.2/manual.html). 

E.g.

Create a `log4j.properties` file and make sure it is available in your classpath. 

The log4j 1.2 jar must be found in your classpath when `log4jruby` is loaded. 

* Place files somewhere already in your classpath such as `$TOMCAT/lib` for Tomcat. 
* Configure classpath via `JAVA_OPTS`
* Amend `$CLASSPATH` at runtime before loading log4jruby. See [examples/setup.rb](examples/setup.rb). 
  
Note: If you're using bundler, you can specify `gem 'log4jruby', require: false` in your Gemfile to delay loading the gem too early.

In a Rails application, add the following in `config/application.rb` or the appropriate `config/environments` file.
```ini
 config.logger = ActiveSupport::TaggedLogging.new(Log4jruby::Logger.get('MyApp'))
```
or older versions of Rails
```ini
 config.logger = Log4jruby::Logger.get('MyApp')
```

### Development

Install log4j for tests and examples

`rake dev:java_deps`