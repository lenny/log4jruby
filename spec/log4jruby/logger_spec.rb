require 'spec_helper'

require 'log4jruby'

module Log4jruby
  describe Logger do
    before { Logger.reset }

    MDC = Java::org.apache.log4j.MDC

    subject { Logger.get('Test', :level => :debug) }

    let(:log4j) { subject.log4j_logger}

    describe 'mapping to Log4j Logger names' do
      it "should prepend 'jruby.' to specified name" do
        expect(Logger.get('MyLogger').log4j_logger.name).to eq('jruby.MyLogger')
      end

      it 'should translate :: into . (e.g. A::B::C becomes A.B.C)' do
        expect(Logger.get('A::B::C').log4j_logger.name).to eq('jruby.A.B.C')
      end
    end

    describe '.get' do
      it 'should return one logger per name' do
        expect(Logger.get('test')).to be_equal(Logger.get('test'))
      end

      it 'should accept attributes hash' do
        logger = Logger.get("loggex#{object_id}", :level => :fatal, :tracing => true)
        expect(logger.log4j_logger.level).to eq(Java::org.apache.log4j.Level::FATAL)
        expect(logger.tracing).to eq(true)
      end

      it 'is thread-safe' do
        loggers = Java::java.util.concurrent.ConcurrentHashMap.new
        threads = []
        10.times do |thread_index|
          threads << Thread.new do
            1000.times do |i|
              loggers.put("#{thread_index}_#{i}", Logger.get(i.to_s))
            end
          end
        end
        threads.each(&:join)
        10.times do |thread_index|
          1000.times do |i|
            expect(loggers.get("#{thread_index}_#{i}")).to equal(Logger.get(i.to_s))
          end
        end
      end
    end

    describe 'root logger' do
      it 'should be accessible via .root' do
        expect(Logger.root.log4j_logger.name).to eq('jruby')
      end

      it 'should always return same object' do
        expect(Logger.root).to be_equal(Logger.root)
      end
    end

    specify 'there should be only one logger per name(retrievable via Logger[name])' do
      expect(Logger['A']).to be_equal(Logger['A'])
    end

    specify 'the backing log4j Logger should be accessible via :log4j_logger' do
      expect(Logger.get('X').log4j_logger).to be_instance_of(Java::org.apache.log4j.Logger)
    end

    describe 'Rails logger compatabity' do
      it 'should respond to <level>?' do
        [:debug, :info, :warn].each do |level|
          expect(subject.respond_to?("#{level}?")).to eq(true)
        end
      end

      it 'should respond to :level' do
        expect(subject.respond_to?(:level)).to eq(true)
      end

      it 'should respond to :flush' do
        expect(subject.respond_to?(:flush)).to eq(true)
      end
    end

    describe '#level =' do
      describe 'accepts symbols or ::Logger constants' do
        [:debug, :info, :warn, :error, :fatal].each do |l|
          example ":#{l}" do
            subject.level = l
            expect(subject.level).to eq(::Logger.const_get(l.to_s.upcase))
          end
        end

        %w(DEBUG INFO WARN ERROR FATAL).each do |l|
          example "::Logger::#{l}"  do
            level_constant = ::Logger.const_get(l.to_sym)
            subject.level = level_constant
            expect(subject.level).to eq(level_constant)
          end
        end
      end
    end

    describe '#level' do
      it 'returns ::Logger constant values' do
        subject.level = ::Logger::DEBUG
        expect(subject.level).to eq(::Logger::DEBUG)
      end

      it 'inherits parent level when not explicitly set' do
        Logger.get('Foo', :level => :fatal)
        expect(Logger.get('Foo::Bar').level).to eq(::Logger::FATAL)
      end
    end

    [:debug, :info, :warn, :error, :fatal].each do |level|
      describe "##{level}" do
        it 'should stringify non-exception argument' do
          expect(log4j).to receive(level).with('7', nil)
          subject.send(level, 7)
        end

        it 'should log ruby exceptions as jruby adapted java RuntinmeExceptions' do
          expect(log4j).to receive(level).with('some error', kind_of(Java::java.lang.RuntimeException))
          begin
            raise 'some error'
          rescue => e
            subject.send(level, e)
          end
        end

        it 'should log java exceptions directly' do
          expect(log4j).to receive(level).
            with(/not a number/m, instance_of(java.lang.NumberFormatException))

          subject.send(level, java.lang.NumberFormatException.new('not a number'))
        end
      end
    end

    [:debug, :info, :warn].each do |level|
      describe "##{level} with block argument" do
        it "should log return value of block argument if #{level} is enabled" do
          expect(log4j).to receive(:isEnabledFor).and_return(true)
          expect(log4j).to receive(level).with('test', nil)
          subject.send(level) { 'test' }
        end

        it "should not evaluate block argument if #{level} is not enabled" do
          expect(log4j).to receive(:isEnabledFor).and_return(false)
          subject.send(level) { raise 'block was called' }
        end
      end
    end

    describe '#tracing?', 'should be inherited' do
      before do
        Logger.root.tracing = nil
        Logger.get('A::B').tracing = nil
        Logger.get('A').tracing = nil
      end

      it 'should return false with tracing unset anywhere' do
        expect(Logger['A'].tracing?).to eq(false)
      end

      it 'should return true with tracing explicitly set to true' do
        expect(Logger.get('A', :tracing => true).tracing?).to eq(true)
      end

      it 'should return true with tracing unset but set to true on parent' do
        Logger.get('A', :tracing => true)
        expect(Logger.get('A::B').tracing?).to eq(true)
      end

      it 'should return false with tracing unset but set to false on parent' do
        Logger.get('A', :tracing => false)
        expect(Logger.get('A::B').tracing?).to eq(false)
      end

      it 'should return true with tracing unset but set to true on root logger' do
        Logger.root.tracing = true
        expect(Logger.get('A::B').tracing?).to eq(true)
      end
    end

    context 'with tracing on' do
      before do
        subject.tracing = true
      end

      it 'should set MDC lineNumber for duration of invocation' do
        line = __LINE__ + 5
        expect(log4j).to receive(:debug) do
          expect(MDC.get('lineNumber')).to eq("#{line}")
        end

        subject.debug('test')

        expect(MDC.get('lineNumber')).to be_nil
      end

      it 'should set MDC fileName for duration of invocation' do
        expect(log4j).to receive(:debug) do
          expect(MDC.get('fileName')).to eq(__FILE__)
        end

        subject.debug('test')

        expect(MDC.get('fileName')).to be_nil
      end

      it 'should not push caller info into MDC if logging level is not enabled' do
        allow(log4j).to receive(:isEnabledFor).and_return(false)

        allow(MDC).to receive(:put).and_raise('MDC was modified')

        subject.debug('test')
      end

      it 'should set MDC methodName for duration of invocation' do
        def some_method
          subject.debug('test')
        end

        expect(log4j).to receive(:debug) do
          expect(MDC.get('methodName')).to eq('some_method')
        end

        some_method

        expect(MDC.get('methodName')).to be_nil
      end
    end

    describe '#log_error(msg, error)' do
      it 'should forward to log4j error(msg, Throwable) signature' do
        expect(log4j).to receive(:error).
        with('my message', instance_of(java.lang.IllegalArgumentException))

        subject.log_error('my message', java.lang.IllegalArgumentException.new)
      end
    end

    describe '#log_fatal(msg, error)' do
      it 'should forward to log4j fatal(msg, Throwable) signature' do
        expect(log4j).to receive(:fatal).
        with('my message', instance_of(java.lang.IllegalArgumentException))

        subject.log_fatal('my message', java.lang.IllegalArgumentException.new)
      end
    end

    describe '#attributes =' do
      it 'should do nothing(i.e. not bomb) if given nil' do
        subject.attributes = nil
      end

      it 'should set values with matching setters' do
        subject.tracing = false
        subject.attributes = {:tracing => true}
        expect(subject.tracing).to eq(true)
      end

      it 'should ignore values without matching setter' do
        subject.attributes = {:no_such_attribute => 'ignore' }
      end
    end

    describe 'formatters (Logger::Formatter)', log_capture: true do
      example 'Logger.get(name, formatter: formatter)' do
        formatter = double('formatter')
        logger = Logger.get('loggername', formatter: formatter)
        expect(logger.formatter).to eq(formatter)
      end

      example '#formatter=(formatter)' do
        formatter = double('formatter')
        logger = Logger.get('loggername')
        logger.formatter = formatter
        expect(logger.formatter).to eq(formatter)
      end

      specify 'msg strings are filtered through Formatter#call(severity, time, name, msg) before sending to log4j' do
        formatter = double('formatter')
        expect(formatter).to receive(:call).with(:debug, instance_of(Time), 'jruby.loggername', 'foo').and_return('formatted')
        logger = Logger.get('loggername', formatter: formatter)
        logger.debug('foo')
        expect(log_capture).to include('formatted')
      end

      specify 'formatters are inherited' do
        formattera = double('formattera', call: 'formatted a')
        formatterb = double('formatterb', call: 'formatted b')
        formatterc = double('formatterc', call: 'formatted c')

        Logger.root.formatter = formattera
        Logger.get('foo', formatter: formatterb)
        Logger.get('foo.bar', formatter: formatterc)

        Logger.root.debug('root')
        Logger.get('foo').debug('foo')
        Logger.get('foo.bar').debug('foo bar')
        Logger.get('foo.bar.baz').debug('foo bar baz')

        expect(log_capture.lines.to_a[0]).to include('formatted a')
        expect(log_capture.lines.to_a[1]).to include('formatted b')
        expect(log_capture.lines.to_a[2]).to include('formatted c')
        expect(log_capture.lines.to_a[3]).to include('formatted c')
      end
    end

    describe '#silence', 'temporarily changes the log level' do
      it 'should change the log level inside the block' do
        subject.silence(::Logger::WARN) do
          expect(subject.level).to eq(::Logger::WARN)
        end
      end

      it 'should restore the log level after the block' do
        subject.silence(::Logger::WARN) do
        end
        expect(subject.level).to eq(::Logger::DEBUG)
      end

      it 'defaults to error level' do
        subject.silence do
          expect(subject.level).to eq(::Logger::ERROR)
        end
      end
    end
  end
end
