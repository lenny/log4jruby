# Log4jruby

`Log4jruby` provides an interface mostly compatible with the standard ruby [Logger](http://ruby-doc.org/core/classes/Logger.html) but backed by  [Log4j](http://logging.apache.org/log4j/1.2/apidocs/index.html). This makes the granular log output configuration, stacktrace output, and other facilities of `log4j` available to Java and Ruby code alike. For projects that extend/integrate Java already dependent on `log4j`, it allows log configuration for Java and Ruby code in one spot.

_Note*_ Currently log4j 1.2 only

* Automatic stacktrace output (including nested causes) for logged exceptions
* Configure Java and Ruby logging together (e.g a single `log4j.properties` file) and gain `log4j` features such as runtime output targets for Ruby code.
* Ability to configure logging per distinct logger name (typically a class)
* Supports inclusion of filename, line number, and method name in log messages via [MDC](http://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/MDC.html). Note: `tracing` must be enabled.
* High level support for class based logging via the `enable_logger` macro. 
* Compatible with the `Rails` logging.


## Usage and examples

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
2022-08-12 17:36:05,819 DEBUG jruby.MyClass foo:20 -- : hello from foo
```

Exceptions are logged with backtraces

```bash
> bundle exec ruby ./examples/nested_ruby_exceptions.rb
# 2022-08-12 17:38:44,743 ERROR jruby.test <main>:31 -- : raised from foo org.jruby.exceptions.RuntimeError: (RuntimeError) raised from foo
	at $_dot_.examples.nested_ruby_exceptions.foo(./examples/nested_ruby_exceptions.rb:15)
	at $_dot_.examples.nested_ruby_exceptions.<main>(./examples/nested_ruby_exceptions.rb:29)
Caused by: org.jruby.exceptions.RuntimeError: (RuntimeError) raised from bar
	at $_dot_.examples.nested_ruby_exceptions.bar(./examples/nested_ruby_exceptions.rb:21)
	at $_dot_.examples.nested_ruby_exceptions.foo(./examples/nested_ruby_exceptions.rb:13)
	... 1 more
Caused by: org.jruby.exceptions.RuntimeError: (RuntimeError) raised from baz
	at $_dot_.examples.nested_ruby_exceptions.baz(./examples/nested_ruby_exceptions.rb:25)
	at $_dot_.examples.nested_ruby_exceptions.bar(./examples/nested_ruby_exceptions.rb:19)
	... 2 more

```

```
logger.warn(exception)
```

```
logger.warn { exception }
```

```
logger.error(msg) { exception)
```

See more in [log4jruby/examples](examples).


## Configuration

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

## Formatters

See [`formatter` in the
Ruby ::Logger docs](https://ruby-doc.org/stdlib-2.7.0/libdoc/logger/rdoc/Logger.html)

Log4jruby passes the same arguments to a `formatter` as would be passed using the standard Ruby Logger given the same logging invocations. 

The default Log4jruby formatter outputs `progname` and `msg` only (as opposed to the default formatter of the Ruby Logger).
Severity, timestamp, and backtraces are handed according to your `Log4j` configuration. 
E.g. [EnhancedPatternLayout](https://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/EnhancedPatternLayout.html).

The output of the `formatter` is passed as the `message` parameter of the [Log4j log methods](https://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/Category.html#log(org.apache.log4j.Priority,%20java.lang.Object).

## Development

Install log4j for tests and examples

`rake dev:java_deps`

```
e.g.

bundle exec ruby ./examples/simple.rb
```

### IRB

```
bundle exec irb
irb(main):002:0> require './examples/setup.rb'
irb(main):003:0> require 'log4jruby'
irb(main):006:0> Log4jruby::Logger.root.debug('test')
DEBUG jruby : - test
```