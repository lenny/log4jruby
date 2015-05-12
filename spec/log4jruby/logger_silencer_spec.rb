require 'spec_helper'
require 'log4jruby'

module Log4jruby
  describe LoggerSilencer do
    before { Logger.reset }
    subject { Logger.get('Test', :level => :debug) }

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
