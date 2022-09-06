# Log4jruby

`Log4jruby` provides an interface mostly compatible with the standard ruby [Logger](http://ruby-doc.org/core/classes/Logger.html) but backed by  [Log4j 2](https://logging.apache.org/log4j/2.x/).
This makes the granular log output configuration, stacktrace output, and other facilities of `log4j` available to Java and Ruby code alike. For projects that extend/integrate Java already dependent on `log4j`, it allows log configuration for Java and Ruby code in one spot.

* Automatic stacktrace output (including nested causes) for logged Java and Ruby exceptions
* Configure Java and Ruby logging together (e.g a single `log4j2.properties` file) and gain `log4j` features such as runtime output targets for Ruby code.
* Ability to configure logging per distinct logger name (typically a class)
* Supports inclusion of filename, line number, and method name in log messages via [ThreadContext](https://logging.apache.org/log4j/2.x/manual/thread-context.html). Note: `tracing` must be enabled.
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

e.g. `log4j2.properties`

See [examples/log4j2.properties](examples/log4j2.properties) for complete example

```ini
 ...
 # JRuby logger
logger.jruby.name = jruby
logger.jruby.level = debug
logger.jruby.additivity = false
logger.jruby.appenderRef.stdout.ref = JRuby
```

Inclusion of filename, line number, and method name in log messages via [ThreadContext](https://logging.apache.org/log4j/2.x/manual/thread-context.html)

e.g.

```ini
appender.jruby.layout.pattern = %d %5p %c %X{methodName}:%X{lineNumber} %m%throwable%n
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
> ruby ./examples/nested_ruby_exceptions.rb
2022-08-25 19:50:47,050 ERROR jruby.test <main>:31 -- : raised from foo org.jruby.exceptions.RuntimeError: (RuntimeError) raised from foo
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

See additional examples in [log4jruby/examples](examples).


## Configuration

Configuring log4j is left to the client via the [standard log4j configuration process](https://logging.apache.org/log4j/2.x/manual/configuration.html).

E.g.

Create a `log4j2.properties` file and make sure it is available in your classpath.

The log4j-api-2.n.jar and log4j-core-2.n.jars must be found in your classpath when `log4jruby` is loaded.

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
E.g. [PatternLayout](https://logging.apache.org/log4j/2.x/manual/layouts.html).

The output of the `formatter` is passed as the `message` parameter of the [Log4j log methods](https://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/Category.html#log(org.apache.log4j.Priority,%20java.lang.Object).

## Development

Install log4j for tests and examples

`rake dev:java_deps`

```
e.g.

ruby ./examples/simple.rb
```

### IRB

```
bundle exec irb
irb(main):002:0> require './examples/setup.rb'
irb(main):003:0> require 'log4jruby'
irb(main):006:0> Log4jruby::Logger.root.debug('test')
DEBUG jruby : - test
```