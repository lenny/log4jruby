require 'spec_helper'

require 'log4jruby/support/log4j_args'

module Log4jruby::Support
  describe Log4jArgs do
    # Failed to define behavior via declarative rules. Just mapping
    # it out explicitly.
    #
    # 0 - nil
    # 1 - throwable
    # 2 - non throwable
    #
    #     arg1, arg2, yielded val
    # 01: 000
    # 02: 001
    # 03: 002
    # 04: 010
    # 05: 011
    # 06: 012
    # ....
    describe 'arg permutations' do
      example '01: no args' do
        expect(Log4jArgs.convert).to eq(['', nil])
      end

      example '02: () { throwable }' do
        e = RuntimeError.new('foo')
        msg, throwable = Log4jArgs.convert { e }
        expect(msg).to eq('foo')
        expect(throwable).to be_kind_of(Java::java.lang.Exception)
      end

      example '03: () { non-throwable })' do
        expect(Log4jArgs.convert { 'foo' }).to eq(['foo', nil])
      end

      example '04: (nil, throwable)' do
        e = RuntimeError.new('foo')
        msg, throwable = Log4jArgs.convert(nil, e)
        expect(msg).to eq('foo')
        expect(throwable.message).to match(/foo/)
      end

      example '05: (nil, throwable) { throwable }' do
        e1 = RuntimeError.new('foo')
        e2 = RuntimeError.new('bar')
        msg, throwable = Log4jArgs.convert(nil, e1) { e2 }
        expect(msg).to eq('foo: bar')
        expect(throwable.message).to match(/foo/)
      end

      example '06: (nil, throwable) { non-throwable }' do
        e1 = RuntimeError.new('foo')
        msg, throwable = Log4jArgs.convert(nil, e1) { 'non-throwable' }
        expect(msg).to eq('foo: non-throwable')
        expect(throwable.message).to match(/foo/)
      end

      example '07: (nil, non-throwable)' do
        expect(Log4jArgs.convert(nil, 'foo')).to eq(['foo', nil])
      end

      example '08: (nil, non-throwable) { throwable }' do
        e1 = RuntimeError.new('foo')
        expect(Log4jArgs.convert(nil, 'bar') { e1 })
          .to eq(['bar foo', nil])
      end

      example '09: (nil, non-throwable) { non-throwable }' do
        expect(Log4jArgs.convert(nil, 'arg2') { 'yielded-text' })
          .to eq(['arg2 yielded-text', nil])
      end

      example '10: (throwable)' do
        e1 = RuntimeError.new('foo')
        msg, throwable = Log4jArgs.convert(e1)
        expect(msg).to eq('foo')
        expect(throwable.message).to match(/foo/)
      end

      example '11: (throwable) { throwable }' do
        e1 = RuntimeError.new('foo')
        e2 = RuntimeError.new('bar')
        expect(Log4jArgs.convert(e1) { e2 })
          .to eq(['foo: bar', nil])
      end

      example '12: (throwable) { non-throwable }' do
        e1 = RuntimeError.new('foo')
        expect(Log4jArgs.convert(e1) { 'bar' })
          .to eq(['foo: bar', nil])
      end

      example '13: (throwable, throwable)' do
        e1 = RuntimeError.new('foo')
        e2 = RuntimeError.new('bar')
        msg, throwable = Log4jArgs.convert(e1, e2)
        expect(msg).to eq('foo')
        expect(throwable.message).to match(/bar/)
      end

      example '14: (throwable, throwable) { throwable }' do
        e1 = RuntimeError.new('foo')
        e2 = RuntimeError.new('bar')
        e3 = RuntimeError.new('baz')
        msg, throwable = Log4jArgs.convert(e1, e2) { e3 }
        expect(msg).to eq('foo: baz')
        expect(throwable.message).to match(/bar/)
      end

      example '15: (throwable, throwable) { non-throwable }' do
        e1 = RuntimeError.new('foo')
        e2 = RuntimeError.new('bar')
        msg, throwable = Log4jArgs.convert(e1, e2) { 'baz' }
        expect(msg).to eq('foo: baz')
        expect(throwable.message).to match(/bar/)
      end

      example '16: (non-throwable, non-throwable)' do
        expect(Log4jArgs.convert('arg1', 'arg2'))
          .to eq(['arg1: arg2', nil])
      end

      example '17: (throwable, non-throwable) { throwable }' do
        e1 = RuntimeError.new('foo')
        e2 = RuntimeError.new('bar')
        expect(Log4jArgs.convert(e1, 'arg2') { e2 })
          .to eq(['foo: arg2 bar', nil])
      end

      example '18: (throwable, non-throwable) { non-throwable }' do
        e1 = RuntimeError.new('foo')
        expect(Log4jArgs.convert(e1, 'arg2') { 'yielded-val' })
          .to eq(['foo: arg2 yielded-val', nil])
      end

      example '19: (non-throwable)' do
        expect(Log4jArgs.convert('non-throwable'))
          .to eq(['non-throwable', nil])
      end

      example '20: (non-throwable) { throwable }' do
        e1 = RuntimeError.new('foo')
        expect(Log4jArgs.convert('non-throwable') { e1 })
          .to eq(['non-throwable: foo', nil])
      end

      example '21: (non-throwable) { non-throwable }' do
        expect(Log4jArgs.convert('arg1') { 'yielded-val' })
          .to eq(['arg1: yielded-val', nil])
      end

      example '22: (non-throwable, throwable)' do
        e1 = RuntimeError.new('foo')
        msg, throwable = Log4jArgs.convert('arg1', e1)
        expect(msg).to eq('arg1')
        expect(throwable.message).to match(/foo/)
      end

      example '23: (non-throwable, throwable) { throwable }' do
        e1 = RuntimeError.new('foo')
        e2 = RuntimeError.new('bar')
        msg, throwable = Log4jArgs.convert('arg1', e1) { e2 }
        expect(msg).to eq('arg1: bar')
        expect(throwable.message).to match(/foo/)
      end

      example '24: (non-throwable, throwable) { non-throwable }' do
        e1 = RuntimeError.new('foo')
        msg, throwable = Log4jArgs.convert('arg1', e1) { 'yielded-val' }
        expect(msg).to eq('arg1: yielded-val')
        expect(throwable.message).to match(/foo/)
      end

      example '25: (non-throwable, non-throwable)' do
        expect(Log4jArgs.convert('arg1', 'arg2'))
          .to eq(['arg1: arg2', nil])
      end

      example '26: (non-throwable, non-throwable) { throwable }' do
        e1 = RuntimeError.new('foo')
        expect(Log4jArgs.convert('arg1', 'arg2') { e1 })
          .to eq(['arg1: arg2 foo', nil])
      end

      example '27: (non-throwable, non-throwable) { non-throwable }' do
        expect(Log4jArgs.convert('arg1', 'arg2') { 'yielded-val' })
          .to eq(['arg1: arg2 yielded-val', nil])
      end
    end

    it 'returns java exceptions directly' do
      e = Java::java.lang.NumberFormatException.new('not a number')
      msg, throwable = Log4jArgs.convert { e }
      expect(msg).to eq('not a number')
      expect(throwable).to be_instance_of(Java::java.lang.NumberFormatException)
    end

    it 'returns wrapped ruby exceptions' do
      e = RuntimeError.new('foo')
      msg, throwable = Log4jArgs.convert(e)
      expect(msg).to eq('foo')
      expect(throwable).to be_kind_of(Java::java.lang.Exception)
    end
  end
end

