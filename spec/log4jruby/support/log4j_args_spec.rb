# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'
require 'logger'
require 'log4jruby/support/log4j_args'

module Log4jruby
  module Support
    describe Log4jArgs do
      # Failed to define behavior via declarative rules. Just mapping
      # it out explicitly.
      #
      # 0 - nil
      # 1 - throwable
      # 2 - non throwable
      #
      #     arg1, yielded val
      # 01: 00
      # 02: 01
      # 03: 02
      # 04: 10
      # 05: 11
      # 06: 12
      # 07: 20
      # 08: 21
      # 09: 22
      describe 'arg permutations' do
        class << self
          def arg2s(arg)
            arg.nil? ? 'nil' : arg
          end

          def it_returns(progname:, msg:, throwable:, &blk)
            it(
              "returns progname: #{arg2s(progname)}, msg: #{arg2s(msg)}, " \
              "throwable: #{arg2s(throwable)}", &blk
            )
          end
        end

        def new_ruby_logger_with_formatter(formatter)
          ruby_logger = ::Logger.new(StringIO.new)
          ruby_logger.formatter = formatter
          ruby_logger
        end

        # rubocop:disable Metrics/AbcSize
        def expect_match(actual, progname:, msg:, throwable:)
          actual_progname, actual_msg, actual_throwable = actual
          expect(actual_progname).to eq(progname)
          expect(actual_msg).to eq(msg)
          if throwable
            expect(actual_throwable).to be_kind_of(Java::java.lang.Exception)
            expect(actual_throwable.message).to match(/#{throwable.message}/)
          else
            expect(actual_throwable).to be_nil
          end
        end

        # rubocop:enable Metrics/AbcSize
        #
        def expect_parity_with_ruby_logger(*args, &blk)
          ruby_progname = nil
          ruby_msg = nil
          formatter = proc { |_, _, progname, msg|
            ruby_progname = progname
            ruby_msg = msg
          }
          ruby_logger = new_ruby_logger_with_formatter(formatter)
          actual_progname, actual_msg, = Log4jArgs.convert(*args, &blk)
          ruby_logger.debug(*args[0, 1], &blk)

          expect(actual_progname).to eq(ruby_progname)
          expect(actual_msg).to eq(ruby_msg)
        end

        describe('01: no args') do
          it_returns(progname: nil, msg: nil, throwable: nil) do
            expect_match(Log4jArgs.convert, progname: nil, msg: nil, throwable: nil)
          end

          it 'matches the Ruby Logger' do
            expect_parity_with_ruby_logger
          end
        end

        describe '02: () { throwable }' do
          let(:e) { RuntimeError.new('foo') }

          it_returns(progname: nil, msg: 'throwable', throwable: 'throwable') do
            expect_match(Log4jArgs.convert { e }, progname: nil, msg: e, throwable: e)
          end

          it 'matches the Ruby Logger' do
            expect_parity_with_ruby_logger { e }
          end
        end

        describe '03: () { non-throwable })' do
          it_returns(progname: nil, msg: 'non-throwable', throwable: nil) do
            expect_match(Log4jArgs.convert { :foo }, progname: nil, msg: :foo, throwable: nil)
          end

          it 'matches the Ruby Logger' do
            expect_parity_with_ruby_logger { :foo }
          end
        end

        describe '04: (throwable)' do
          let(:e1) { RuntimeError.new('exceptionmessage') }

          it_returns(progname: nil, msg: 'throwable', throwable: 'throwable') do
            expect_match(Log4jArgs.convert(e1),
                         progname: nil, msg: e1, throwable: e1)
          end

          it 'matches the Ruby Logger' do
            expect_parity_with_ruby_logger(e1)
          end
        end

        describe '05: (throwable1) { throwable2 }' do
          let(:e1) { RuntimeError.new('error1') }
          let(:e2) { RuntimeError.new('error2') }

          it_returns(progname: 'throwable1', msg: 'throwable2', throwable: 'throwable2') do
            expect_match(Log4jArgs.convert(e1) { e2 },
                         progname: e1, msg: e2, throwable: e2)
          end

          it 'matches the Ruby Logger' do
            expect_parity_with_ruby_logger(e1) { e2 }
          end
        end

        describe '06: (throwable) { non-throwable }' do
          let(:e1) { RuntimeError.new('error1') }

          it_returns(progname: 'throwable', msg: 'non-throwable', throwable: 'throwable') do
            expect_match(Log4jArgs.convert(e1) { :nonthrowable },
                         progname: e1, msg: :nonthrowable, throwable: e1)
          end

          it 'matches the Ruby Logger' do
            expect_parity_with_ruby_logger(e1) { :nonthrowable }
          end
        end

        describe '07: (non-throwable)' do
          it_returns(progname: nil, msg: 'non-throwable', throwable: nil) do
            expect_match(Log4jArgs.convert('non-throwable'),
                         progname: nil, msg: 'non-throwable', throwable: nil)
          end

          it 'matches the Ruby Logger' do
            expect_parity_with_ruby_logger('non-throwable')
          end
        end

        describe '08: (non-throwable) { throwable }' do
          let(:e1) { RuntimeError.new('error1') }

          it_returns(progname: 'non-throwable', msg: 'throwable', throwable: 'throwable') do
            expect_match(Log4jArgs.convert('non-throwable') { e1 },
                         progname: 'non-throwable', msg: e1, throwable: e1)
          end

          it 'matches the Ruby Logger' do
            expect_parity_with_ruby_logger('non-throwable') { e1 }
          end
        end

        describe '09: (non-throwable1) { non-throwable2 }' do
          it_returns(progname: :nonthrowable1, msg: :nonthrowable2, throwable: nil) do
            expect_match(Log4jArgs.convert(:nonthrowable1) { :nonthrowable2 },
                         progname: :nonthrowable1, msg: :nonthrowable2, throwable: nil)
          end

          it 'matches the Ruby Logger' do
            expect_parity_with_ruby_logger(:nonthrowable1) { :nonthrowable2 }
          end
        end

        it 'returns java exceptions directly' do
          e = Java::java.lang.NumberFormatException.new('not a number')
          _, _, throwable = Log4jArgs.convert { e }
          expect(throwable).to be_instance_of(Java::java.lang.NumberFormatException)
        end

        it 'returns wrapped ruby exceptions' do
          e = RuntimeError.new('foo')
          _, _, throwable = Log4jArgs.convert(e)
          expect(throwable).to be_kind_of(Java::java.lang.Exception)
        end
      end
    end
  end
end
