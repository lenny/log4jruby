

# Log4jruby

* https://github.com/lenny/log4jruby

## Description:

Log4jruby is a thin wrapper around the {Log4j Logger}[http://logging.apache.org/log4j/1.2/apidocs/index.html].
It is geared more toward those who are using JRuby to integrate with and build on top of Java code that uses Log4j.
The ```Log4jruby::Logger``` provides an interface much like the standard ruby [Logger](http://ruby-doc.org/core/classes/Logger.html).
Logging is configured via traditional Log4j methods.

The primary use case (i.e., mine) for this library is that you are already up and running with Log4j and now you want
to use it for your Ruby code too. There is not much help here for configuration. In our environment, we deploy Rails
apps that call and extend Java code into Tomcat as WARs and use a log4j.properties to configure. For the most part,
all there is to using log4jruby is making sure the log4j jar is <tt>required</tt> and that Log4j is at least minimally
configured (e.g., log4j.properties in the CLASSPATH). The examples should give you the idea.

### Features

* Filename, line number, and method name are available (if tracing is on) to your appender layout via {MDC}[http://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/MDC.html].
* Exceptions can be logged directly and are output with backtraces. Java Exceptions (i.e., NativeExceptions)
  are logged with full java backtrace(including nested exceptions).
* Logging config for your ruby code can be added to your existing configuration. Ruby logger names are mapped to dot separated names prefixed with <tt>.jruby</tt>

    log4j.appender.Ruby=org.apache.log4j.ConsoleAppender
    log4j.appender.Ruby.layout=org.apache.log4j.PatternLayout
    log4j.appender.Ruby.layout.ConversionPattern=%5p %.50X{fileName} %X{methodName}:%X{lineNumber} - %m%n

    log4j.logger.jruby=info,Ruby
    log4j.logger.jruby.MyClass=debug

### Configuration

As noted above, configuring log4j is left to the client. **You must load and configure log4j before requiring log4jruby**.
There are multiple ways to do so. 
In our environment, we deploy Rails apps that call and extend Java code to Tomcat as WAR files.
We provision our app servers with ```log4j.jar``` and a ```log4j.properties``` file in in ```$TOMCAT_HOME/lib```. 
You may also addd log4j.jar and path to config file into CLASSPATH via environment variables, JAVA_OPTS, JAVA_OPTS, etc...
Or add them into ```$CLASSPATH``` at runtime before loading log4jruby. See [examples/setup.rb](examples/setup.rb). 
  
Note: If you're using bundler, you can specify ```gem 'log4jruby', require: false``` in your Gemfile to delay loading the gem too early.
  
In a Rails application, add the following in ```config/application.rb``` or the appropriate ```config/environments``` file.
   
    config.logger = ActiveSupport::TaggedLogging.new(Log4jruby::Logger.get('MyApp'))
    
or older versions of Rails

    config.logger = Log4jruby::Logger.get('MyApp')
                           
### Examples

    def foo
      logger.debug("hello from foo")
      bar
    rescue => e
      logger.error(e)
    end

    DEBUG jruby.MyClass foo:17 - hello from foo
    DEBUG jruby.MyClass bar:24 - hello from bar
    DEBUG jruby.MyClass baz:29 - hello from baz
    ERROR jruby.MyClass foo:20 - error from baz
      examples/simple.rb:30:in `baz'
      examples/simple.rb:25:in `bar'
      examples/simple.rb:18:in `foo'
      examples/simple.rb:35:in `(root)'

See more in [log4jruby/examples](examples).

### Usage

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

    INFO jruby.MyModule.A my_class_method:14 - hello from class method
    INFO jruby.MyModule.A my_method:19 - hello from instance method

See more in [log4jruby/examples](examples)..
They should be runnable from the source.

