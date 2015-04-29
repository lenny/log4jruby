require 'spec_helper'

require 'log4jruby/support/log4j_args'

module Log4jruby
  module Support
    describe Log4jArgs do
      context 'with only a non-exception' do
        it 'should return [msg, nil]' do
          expect(Log4jArgs.convert('testing')).to eq(['testing', nil])
        end
      end

      context 'with only a block' do
        it 'should return [msg, nil]' do
          expect(Log4jArgs.convert { 'testing' }).to eq(['testing', nil])
        end
      end

      context 'with only a ruby exception' do
        it 'should return [<stringified exception message > + <backtrace>, nil]' do
          ruby_error = RuntimeError.new('my message')
          allow(ruby_error).to receive(:backtrace).and_return(%w(line1 line2))

          expect(Log4jArgs.convert(ruby_error)).to eq(["my message\n  line1\n  line2", nil])
        end
      end

      context 'with a message and ruby exception' do
        it 'should return [<msg> + <stringified exception message > + <backtrace>, nil]' do
          ruby_error = RuntimeError.new('my error')
          allow(ruby_error).to receive(:backtrace).and_return(%w(line1 line2))

          expect(Log4jArgs.convert('my message', ruby_error)).to eq(["my message\nmy error\n  line1\n  line2", nil])
        end
      end

      context 'with a NativeException',
              "should return [<exception message> + <backtrace> + 'NativeException:', <wrapped java exception>]" do
        let(:native_exception) do
          native_exception = nil
          begin
            java.lang.Long.new('not a number')
          rescue NativeException => e
            native_exception = e
          end
          native_exception
        end

        specify 'first arg should include ruby exception message' do
          expect(Log4jArgs.convert(native_exception)[0]).to include('not a number')
        end

        specify 'first arg should include ruby exception backtrace' do
          expect(Log4jArgs.convert(native_exception)[0]).to include(__FILE__.to_s)
        end

        specify "first arg should end with \nNativeException:" do
          expect(Log4jArgs.convert(native_exception)[0]).to match(/\nNativeException:$/)
        end

        specify 'second arg is wrapped java exception' do
          expect(Log4jArgs.convert(native_exception)[1]).to be_instance_of(java.lang.NumberFormatException)
        end
      end

      context 'with a message and a NativeException',
              'should return [<message> + <exception message> + <backtrace>, <wrapped java exception>]' do

        let(:native_exception) do
          native_exception = nil
          begin
            java.lang.Long.new('not a number')
          rescue NativeException => e
            native_exception = e
          end
          native_exception
        end

        specify 'first arg should include message' do
          expect(Log4jArgs.convert('my message', native_exception)[0]).to include('my message')
        end

        specify 'first arg should include ruby exception message' do
          expect(Log4jArgs.convert('my message', native_exception)[0]).to include('not a number')
        end

        specify 'first arg should include ruby exception backtrace' do
          expect(Log4jArgs.convert('my message', native_exception)[0]).to include(__FILE__.to_s)
        end

        specify 'second arg is the wrapped java exception' do
          expect(Log4jArgs.convert('my message', native_exception)[1]).to be_instance_of(java.lang.NumberFormatException)
        end
      end


      context 'with unwrapped java exception' do
        it "should return ['', throwable]" do
          throwable = java.lang.IllegalArgumentException.new

          expect(Log4jArgs.convert(throwable)).to eq(['', throwable])
        end
      end
    end
  end
end
