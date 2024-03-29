# frozen_string_literal: true

require 'spec_helper'

require 'log4jruby'

ThreadContext = Java::org.apache.logging.log4j.ThreadContext
Log4j = Java::org.apache.logging.log4j

module Log4jruby
  describe Logger do
    before do
      Support::LogManager.reset
    end

    subject { Logger.get('Test', level: :debug) }

    let(:log4j) { subject.log4j_logger }

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
        logger = Logger.get("loggex#{object_id}", level: :fatal, tracing: true)
        expect(logger.log4j_logger.level).to eq(Log4j.Level::FATAL)
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
      expect(Logger.get('X').log4j_logger).to be_instance_of(Log4j.core.Logger)
    end

    describe 'Rails logger compatabity' do
      it 'should respond to <level>?' do
        %i[debug info warn].each do |level|
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
        %i[debug info warn error fatal].each do |l|
          example ":#{l}" do
            subject.level = l
            expect(subject.level).to eq(::Logger.const_get(l.to_s.upcase))
          end
        end

        %w[DEBUG INFO WARN ERROR FATAL].each do |l|
          example "::Logger::#{l}" do
            level_constant = ::Logger.const_get(l.to_sym)
            subject.level = level_constant
            expect(subject.level).to eq(level_constant)
          end
        end
      end
    end

    describe '#level' do
      def create_logger_config(name:, level:)
        config = Log4j.LogManager.getContext(false).configuration
        logger_config = Log4j.core.config.LoggerConfig
                             .createLogger(false,
                                           level,
                                           name,
                                           'true',
                                           [].to_java(Log4j.core.config.AppenderRef),
                                           [].to_java(Log4j.core.config.Property),
                                           config, nil)
        config.addLogger(name, logger_config)
      end

      it 'returns ::Logger constant values' do
        subject.level = ::Logger::DEBUG
        expect(subject.level).to eq(::Logger::DEBUG)
      end

      it 'inherits configured parent level when not explicitly set' do
        create_logger_config(name: 'jruby.Foo', level: Log4j.Level::DEBUG)
        expect(Logger.get('Foo::Bar').level).to eq(::Logger::DEBUG)
      end

      # log4j2 logger attributes are inherited from configs only
      # as opposed to Logger instances
      it 'does not inherit parent instance config' do
        create_logger_config(name: 'jruby.Foo', level: Log4j.Level::DEBUG)
        expect(Logger.get('Foo', level: :fatal).level).to eq(::Logger::FATAL)
        expect(Logger.get('Foo::Bar').level).to eq(::Logger::DEBUG)
      end
    end

    %i[debug info warn error fatal].each do |level|
      describe "##{level}" do
        it 'should stringify non-exception argument via default formatter' do
          expect(log4j).to receive(level).with(/7/, nil)
          subject.send(level, 7)
        end

        if Support::JrubyVersion.native_ruby_stacktraces_supported?
          it 'sends jruby adapted ruby exceptions directly to log4j' do
            expect(log4j).to receive(level).with(/some error/,
                                                 kind_of(Java::java.lang.RuntimeException))
            begin
              raise 'some error'
            rescue StandardError => e
              subject.send(level, e)
            end
          end
        else
          it 'does not send ruby exceptions directly to log4j' do
            expect(log4j).to receive(level).with(/some error/, nil)
            begin
              raise 'some error'
            rescue StandardError => e
              subject.send(level, e)
            end
          end
        end

        it 'should log java exceptions directly' do
          expect(log4j).to receive(level)
            .with(/not a number/, instance_of(java.lang.NumberFormatException))
          subject.send(level, java.lang.NumberFormatException.new('not a number'))
        end
      end
    end

    %i[debug info warn].each do |level|
      describe "##{level} with block argument" do
        it "should log return value of block argument if #{level} is enabled" do
          expect(log4j).to receive(:isEnabled).and_return(true)
          expect(log4j).to receive(level).with(/test/, nil)
          subject.send(level) { 'test' }
        end

        it "should not evaluate block argument if #{level} is not enabled" do
          expect(log4j).to receive(:isEnabled).and_return(false)
          subject.send(level) { raise 'block was called' }
        end
      end
    end

    describe 'exception stringification', log_capture: true do
      context 'with native ruby backtraces supported' do
        before do
          allow(Support::JrubyVersion).to receive(:native_ruby_stacktraces_supported?)
            .and_return(true)
        end

        it 'passes exceptions to formatter intact' do
          formatter = double('formatter')
          expect(formatter).to receive(:call).with(anything, anything, 'rescued error',
                                                   instance_of(RuntimeError))
          logger = Logger.get('loggername', formatter: formatter)
          begin
            raise 'some error'
          rescue StandardError => e
            logger.error('rescued error') { e }
          end
        end
      end

      context 'without support for native ruby backtraces' do
        before do
          allow(Support::JrubyVersion).to receive(:native_ruby_stacktraces_supported?)
            .and_return(false)
        end

        # Can't use a formatter to stringify exceptions because
        # [ActiveSupport::TaggedLogging breaks formatters](https://github.com/lenny/log4jruby/issues/27)
        # stringifies arguments itself
        it 'stringifies exceptions before invoking formatter' do
          formatter = double('formatter')
          expect(formatter).to receive(:call).with(anything, anything, 'rescued error',
                                                   /#{__FILE__}/)
          logger = Logger.get('loggername', formatter: formatter)
          begin
            raise 'some error'
          rescue StandardError => e
            logger.error('rescued error') { e }
          end
        end
      end
    end

    describe '#tracing?', 'should be inherited' do
      it 'should return false with tracing unset anywhere' do
        expect(Logger['A'].tracing?).to eq(false)
      end

      it 'should return true with tracing explicitly set to true' do
        expect(Logger.get('A', tracing: true).tracing?).to eq(true)
      end

      it 'should return true with tracing unset but set to true on parent' do
        Logger.get('A', tracing: true)
        expect(Logger.get('A::B').tracing?).to eq(true)
      end

      it 'should return false with tracing unset but set to false on parent' do
        Logger.get('A', tracing: false)
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

      it 'should set ThreadContext lineNumber for duration of invocation' do
        line = __LINE__ + 5
        expect(log4j).to receive(:debug) do
          expect(ThreadContext.get('lineNumber')).to eq(line.to_s)
        end

        subject.debug('test')

        expect(ThreadContext.get('lineNumber')).to be_nil
      end

      it 'should set ThreadContext fileName for duration of invocation' do
        expect(log4j).to receive(:debug) do
          expect(ThreadContext.get('fileName')).to eq(__FILE__)
        end

        subject.debug('test')

        expect(ThreadContext.get('fileName')).to be_nil
      end

      it 'should not push caller info into ThreadContext if logging level is not enabled' do
        allow(log4j).to receive(:isEnabled).and_return(false)

        allow(ThreadContext).to receive(:put).and_raise('ThreadContext was modified')

        subject.debug('test')
      end

      it 'should set ThreadContext methodName for duration of invocation' do
        def some_method
          subject.debug('test')
        end

        expect(log4j).to receive(:debug) do
          expect(ThreadContext.get('methodName')).to eq('some_method')
        end

        some_method

        expect(ThreadContext.get('methodName')).to be_nil
      end
    end

    describe '#log_error(msg, error)' do
      it 'should forward to log4j error(msg, Throwable) signature' do
        expect(log4j).to receive(:error)
          .with(/my message/, instance_of(java.lang.IllegalArgumentException))
        subject.log_error('my message', java.lang.IllegalArgumentException.new)
      end
    end

    describe '#log_fatal(msg, error)' do
      it 'should forward to log4j fatal(msg, Throwable) signature' do
        expect(log4j).to receive(:fatal)
          .with(/my message/, instance_of(java.lang.IllegalArgumentException))
        subject.log_fatal('my message', java.lang.IllegalArgumentException.new)
      end
    end

    describe '#attributes =' do
      it 'should do nothing(i.e. not bomb) if given nil' do
        subject.attributes = nil
      end

      it 'should set values with matching setters' do
        subject.tracing = false
        subject.attributes = { tracing: true }
        expect(subject.tracing).to eq(true)
      end

      it 'should ignore values without matching setter' do
        subject.attributes = { no_such_attribute: 'ignore' }
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

      specify 'msg strings are filtered through Formatter#call(severity, time, name, msg) ' \
              'before sending to log4j' do
        formatter = double('formatter')
        expect(formatter).to receive(:call).with(:debug, instance_of(Time), :foo,
                                                 :bar).and_return('formatted')
        logger = Logger.get('loggername', formatter: formatter)
        logger.debug(:foo) { :bar }
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

      specify 'default formatter matches ::Logger::Formatter with level and time stripped out' do
        expect(log4j).to receive(:debug).with('-- progname: message', nil)
        subject.debug('progname') { 'message' }
      end
    end

    describe '#silence', 'temporarily changes the log level' do
      it 'should change the log level inside the block' do
        subject.silence(::Logger::WARN) do
          expect(subject.level).to eq(::Logger::WARN)
        end
      end

      it 'should restore the log level after the block' do
        expect(subject.level).to eq(::Logger::DEBUG)
        subject.silence(::Logger::WARN) do
          expect(subject.level).to eq(::Logger::WARN)
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
