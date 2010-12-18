require 'spec_helper'

require 'log4jruby'

module Log4jruby
  describe Log4jArgs do
    context "with only a non-exception" do
      it "should return [msg, nil]" do
        Log4jArgs.convert("testing").should == ["testing", nil]
      end
    end

    context "with only a block" do
      it "should return [msg, nil]" do
        Log4jArgs.convert { "testing" }.should == ["testing", nil]
      end
    end

    context "with only a ruby exception" do
      it "should return [<stringified exception message > + <backtrace>, nil]" do
        ruby_error = RuntimeError.new("my message")
        ruby_error.stub(:backtrace).and_return(["line1", "line2"])

        Log4jArgs.convert(ruby_error).should == ["my message\n  line1\n  line2", nil]
      end
    end

    context "with a message and ruby exception" do
      it "should return [<msg> + <stringified exception message > + <backtrace>, nil]" do
        ruby_error = RuntimeError.new('my error')
        ruby_error.stub(:backtrace).and_return(["line1", "line2"])

        Log4jArgs.convert('my message', ruby_error).should == ["my message\nmy error\n  line1\n  line2", nil]
      end
    end

    context "with a NativeException",
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

      specify "first arg should include ruby exception message" do
        Log4jArgs.convert(native_exception)[0].should include("not a number")
      end

      specify "first arg should include ruby exception backtrace" do
        Log4jArgs.convert(native_exception)[0].should include(__FILE__.to_s)
      end

      specify "first arg should end with \nNativeException:" do
        Log4jArgs.convert(native_exception)[0].should match(/\nNativeException:$/)
      end

      specify "second arg is wrapped java exception" do
        Log4jArgs.convert(native_exception)[1].should be_instance_of(java.lang.NumberFormatException)
      end
    end

    context "with a message and a NativeException",
      "should return [<message> + <exception message> + <backtrace>, <wrapped java exception>]" do

      let(:native_exception) do
        native_exception = nil
        begin
          java.lang.Long.new('not a number')
        rescue NativeException => e
          native_exception = e
        end
        native_exception
      end

      specify "first arg should include message" do
        Log4jArgs.convert('my message', native_exception)[0].should include("my message")
      end

      specify "first arg should include ruby exception message" do
        Log4jArgs.convert('my message', native_exception)[0].should include("not a number")
      end

      specify "first arg should include ruby exception backtrace" do
        Log4jArgs.convert('my message', native_exception)[0].should include(__FILE__.to_s)
      end

      specify "second arg is the wrapped java exception" do
        Log4jArgs.convert('my message', native_exception)[1].should be_instance_of(java.lang.NumberFormatException)
      end
    end


    context "with unwrapped java exception" do
      it "should return ['', throwable]" do
        throwable = java.lang.IllegalArgumentException.new

        Log4jArgs.convert(throwable).should == ['', throwable]
      end
    end


  end
end