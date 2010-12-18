require 'spec_helper'

require 'log4jruby'

module Log4jruby
  describe Logger do
    MDC = Java::org.apache.log4j.MDC

    subject { Logger.get('Test', :level => :debug) }

    before do
      @log4j = subject.log4j_logger
    end

    describe "mapping to Log4j Logger names" do
      it "should prepend 'jruby.' to specified name" do
        Logger.get('MyLogger').log4j_logger.name.should == 'jruby.MyLogger'
      end

      it "should translate :: into . (e.g. A::B::C becomes A.B.C)" do
        Logger.get('A::B::C').log4j_logger.name.should == "jruby.A.B.C"
      end
    end
    
    describe ".get" do
      it "should return one logger per name" do
        Logger.get('test').should be_equal(Logger.get('test'))
      end
      
      it "should accept attributes hash" do
        logger = Logger.get('test', :level => :debug, :tracing => true)
        logger.log4j_logger.level.should == Java::org.apache.log4j.Level::DEBUG
        logger.tracing.should == true
      end
    end

    describe "root logger" do
      it "should be accessible via .root" do
        Logger.root.log4j_logger.name.should == 'jruby'
      end
      
      it "should always return same object" do
        Logger.root.should be_equal(Logger.root)
      end
    end
    
    specify "there is only one logger per name(retrievable via Logger[name])" do
      Logger["A"].should be_equal(Logger["A"])
    end

    specify "backing log4j Logger should be accessible via :log4j_logger" do
      Logger.get('X').log4j_logger.should be_instance_of(Java::org.apache.log4j.Logger)
    end
    
    describe 'Rails logger compatabity' do
      it "should respond to <level>?" do
        [:debug, :info, :warn].each do |level|
          subject.respond_to?("#{level}?").should == true
        end
      end
      
      it "should respond to :level" do
        subject.respond_to?(:level).should == true
      end
      
      it "should respond to :flush" do
        subject.respond_to?(:flush).should == true
      end
    end
    
    describe "#level =" do
      it "should accept :debug" do
        subject.level = :debug
        subject.level.should == Java::org.apache.log4j.Level::DEBUG
      end
      
      it "should accept :info" do
        subject.level = :info
        subject.level.should == Java::org.apache.log4j.Level::INFO
      end
      
      it "should accept :warn" do
        subject.level = :warn
        subject.level.should == Java::org.apache.log4j.Level::WARN
      end
      
      it "should accept :error" do
        subject.level = :error
        subject.level.should == Java::org.apache.log4j.Level::ERROR
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

    describe 'tracing' do
      it "should use setting for logger if set" do
        subject.tracing = false
        subject.tracing?.should be_false
      end
      
      it "should use value from first ancestor with setting if not set" do
        loggera = Logger['A']
        loggerb = Logger['A::B']
        loggerc = Logger['A::B::C']
            
        loggera.tracing = true
        
        loggerc.tracing?.should be_true
        
        loggerb.tracing = false
        
        loggera.tracing?.should be_true
        loggerb.tracing?.should be_false
        loggerc.tracing?.should be_false  
      end
      
      it "should use value from root if not set and no parent" do
        logger = Logger['value_from_root_if_not_set_and_no_parent']
            
        logger.tracing?.should be_false
        
        Logger.root.tracing = true
        
        logger.tracing?.should be_true
      end
    
      it "should be false if not set at all" do
        loggera = Logger['A']
        loggerb = Logger['A::B']
        loggerc = Logger['A::B::C']
            
        loggerc.tracing?.should be_false
      end
    end

    context "with tracing on" do
      before do
        subject.tracing = true
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
      before { subject.tracing = false }
      
      it "should set MDC with blank values" do
        @log4j.should_receive(:debug) do
          MDC.get('fileName').should == ''
          MDC.get('methodName').should == ''
          MDC.get('lineNumber').should == ''
        end

        subject.debug('test')
      end
    end

    specify "ruby exceptions are logged with backtrace" do
      @log4j.should_receive(:debug).with(/some error.*#{__FILE__}/m, nil)

      begin;
        raise "some error"
      rescue => e
        subject.debug(e)
      end
    end

    specify "NativeExceptions are logged with backtrace and wrapped Throwable" do
      @log4j.should_receive(:error).
        with(/my message/, instance_of(java.lang.NumberFormatException))

      native_exception = nil
      begin
        java.lang.Long.new('not a number')
      rescue NativeException => e
        native_exception = e
      end

      subject.log_error('my message', native_exception)
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
        @log4j.should_receive(:isEnabledFor).and_return(false)
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

    describe "#attributes =" do
      it "should do nothing(i.e. not bomb) if given nil" do
        subject.attributes = nil
      end
      
      it "should set values with matching setters" do
        subject.tracing = false
        subject.attributes = {:tracing => true}
        subject.tracing.should == true
      end
      
      it "should ignore values without matching setter" do
        subject.attributes = {:no_such_attribute => 'ignore' }
      end
    end
  end

end
