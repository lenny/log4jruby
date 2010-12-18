module Log4jruby
  class Log4jArgs
    class << self
      def convert(object = nil, exception = nil)
        msg = ''

        if exception
          msg << object.to_s
        else
          exception = block_given? ? yield : object
        end

        if exception.is_a?(NativeException)
          append_ruby_error(msg, exception)
          msg << "\nNativeException:"
          exception = exception.cause
        elsif exception.is_a?(::Exception)
          append_ruby_error(msg, exception)
          exception = nil
        elsif !exception.is_a?(java.lang.Throwable)
          msg << exception.to_s
          exception = nil
        end

        [msg, exception]
      end

      private

      def append_ruby_error(msg, error)
        append(msg, "#{error}\n  " + error.backtrace.join("\n  "))
      end

      def append(msg, s)
        msg << "\n#{s}"
        msg.lstrip!
      end
    end
  end
end