require File.dirname(__FILE__) + '/../spec_helper'

require 'log4jruby'

module Log4jruby
  describe Logger do
    MDC = Java::org.apache.log4j.MDC

    subject { Logger.new('Test', :level => :debug) }

    before do
      @log4j = subject.log4j_logger
    end

    describe "mapping to Log4j Logger names" do
      it "should prepend 'jruby.' to specified name" do
        Logger.new('MyLogger').log4j_logger.name.should == 'jruby.MyLogger'
      end

      it "should translate :: into ." do
        Logger.new('MyModule::MyClass').log4j_logger.name.should == "jruby.MyModule.MyClass"
      end
    end
    
    specify "it should accept attributes hash in initalizer" do
      logger = Logger.new('test', :level => :debug, :trace => true)
      logger.log4j_logger.level.should == Java::org.apache.log4j.Level::DEBUG
      logger.trace.should == true
    end

    describe "root logger" do
      it "should be accessible via .root" do
        Logger.root.log4j_logger.name.should == 'jruby'
      end
    end

    specify "backing log4j Logger should be accessible via :log4j_logger" do
      Logger.new('X').log4j_logger.should be_instance_of(Java::org.apache.log4j.Logger)
    end
    
    describe "log level setter" do
      it "should accept :debug" do
        subject.level = :debug
        subject.log4j_logger.level.should == Java::org.apache.log4j.Level::DEBUG
      end
      
      it "should accept :info" do
        subject.level = :info
        subject.log4j_logger.level.should == Java::org.apache.log4j.Level::INFO
      end
      
      it "should accept :warn" do
        subject.level = :warn
        subject.log4j_logger.level.should == Java::org.apache.log4j.Level::WARN
      end
      
      it "should accept :error" do
        subject.level = :error
        subject.log4j_logger.level.should == Java::org.apache.log4j.Level::ERROR
      end
    end

    it "should log simple string" do
      @log4j.should_receive(:debug).with('test', nil)
      subject.debug('test')  
    end

    it "should stringify non-exception argument" do
      @log4j.should_receive(:debug).with('7', nil)
      subject.debug(7)
    end  

    it "should accept block for msg in order to avoid evaluation" do
      @log4j.should_receive(:debug).with('test', nil)
      subject.debug { 'test' }
    end

    it "should use global setting for :trace if not set explicitly for logger" do
      Logger.stub(:trace).and_return(true)

      Logger.new('test').tracing?.should == true
    end

    context "with tracing on" do
      before do
        subject.trace = true
      end

      it "should set MDC lineNumber for duration of invocation" do
        line = __LINE__ + 5
        @log4j.should_receive(:debug) do
          MDC.get('lineNumber').should == "#{line}"
        end

        subject.debug('test')

        MDC.get('lineNumber').should be_nil
      end

      it "should set MDC fileName for duration of invocation" do
        @log4j.should_receive(:debug) do
          MDC.get('fileName').should == __FILE__
        end

        subject.debug('test')

        MDC.get('fileName').should be_nil
      end

      it "should not push caller info into MDC if logging level is not enabled" do
        @log4j.stub(:isDebugEnabled).and_return(false)

        MDC.stub(:put).and_raise("MDC was modified")

        subject.debug('test')
      end

      it "should set MDC methodName for duration of invocation" do
        def some_method
          subject.debug('test')
        end

        @log4j.should_receive(:debug) do
          MDC.get('methodName').should == 'some_method'
        end

        some_method()

        MDC.get('methodName').should be_nil
      end
    end

    context "with tracing off" do
      it "should set MDC with blank values" do
        @log4j.should_receive(:debug) do
          MDC.get('fileName').should == ''
          MDC.get('methodName').should == ''
          MDC.get('lineNumber').should == ''
        end

        subject.debug('test')
      end
    end

    context "with wrapped native java exception" do
      it "should forward to log4j (msg, Throwable) signature" do
        @log4j.should_receive(:debug).
        with('', instance_of(java.lang.NumberFormatException))

        native_exception = nil
        begin
          java.lang.Long.new('not a number')
        rescue NativeException => e
          native_exception = e
        end

        subject.debug(native_exception)
      end 
    end

    context "with message and wrapped native java exception" do
      it "should forward to log4j (msg, Throwable) signature" do
        @log4j.should_receive(:error).
        with('my message', instance_of(java.lang.NumberFormatException))

        native_exception = nil
        begin
          java.lang.Long.new('not a number')
        rescue NativeException => e
          native_exception = e
        end

        subject.log_error('my message', native_exception)
      end
    end

    context "with unwrapped java exception" do
      it "should forward to log4j (msg, Throwable) signature" do 
        @log4j.should_receive(:debug).
        with('', instance_of(java.lang.IllegalArgumentException))

        subject.debug(java.lang.IllegalArgumentException.new)
      end
    end

    context "with ruby exception" do
      it "should stringify message and backtrace" do
        ruby_error = RuntimeError.new("my message")
        ruby_error.stub(:backtrace).and_return(["line1", "line2"])

        @log4j.should_receive(:debug).with("my message\n  line1\n  line2", nil)

        subject.debug(ruby_error) 
      end 
    end

    context "message and ruby exception" do
      it "should concatenate stringified backtrace to message" do
        ruby_error = RuntimeError.new('my error')
        ruby_error.stub(:backtrace).and_return(["line1", "line2"])

        @log4j.should_receive(:error).with("my message\nmy error\n  line1\n  line2", nil)

        subject.log_error('my message', ruby_error)
      end
    end

    describe '#debug' do
      it "should avoid parameter evaluation if given block and debug level is not enabled" do
        @log4j.should_receive(:isDebugEnabled).and_return(false)
        subject.debug { raise 'block was called' }   
      end
    end

    describe '#info' do
      it "should avoid parameter evaluation if given block and info level is not enabled" do
        @log4j.should_receive(:isInfoEnabled).and_return(false)
        subject.info { raise 'block was called' }         
      end
    end

    describe '#warn' do
      it "should avoid parameter evaluation if given block and warn level is not enabled" do
        @log4j.should_receive(:isWarnEnabled).and_return(false)
        subject.warn { raise 'block was called' } 
      end
    end

    describe '#error' do
      it "should always do parameter evaluation even when given a block" do
        @log4j.should_receive(:error).with("message", nil)
        subject.error { 'message' }
      end
    end

    describe '#fatal' do
      it "should always do parameter evaluation even when given a block" do
        @log4j.should_receive(:fatal).with("message", nil)
        subject.fatal { 'message' }
      end
    end

    describe '#log_error(msg, error)' do
      it "should forward to log4j error(msg, Throwable) signature" do
        @log4j.should_receive(:error).
        with('my message', instance_of(java.lang.IllegalArgumentException))

        subject.log_error('my message', java.lang.IllegalArgumentException.new)
      end
    end

    describe '#log_fatal(msg, error)' do
      it "should forward to log4j fatal(msg, Throwable) signature" do
        @log4j.should_receive(:fatal).
        with('my message', instance_of(java.lang.IllegalArgumentException))

        subject.log_fatal('my message', java.lang.IllegalArgumentException.new)
      end
    end


  end

end
