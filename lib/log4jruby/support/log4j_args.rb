# frozen_string_literal: true

module Log4jruby
  module Support
    # Translate logger args for use by Ruby Logger formatter and log4j.
    # Intention is to matches the Ruby Logger for common parameters
    class Log4jArgs
      class << self
        # Adapt permutations of ruby Logger arguments into arguments
        # for Log4j Logger with explicit throwable when possible.
        #
        # The :progname and :msg returned by this method matches
        # the arguments that would be passed to a
        # Ruby Logger#formatter
        #
        # @param object [String | Exception] - Correlates to the `progname` param of the
        #     ruby Logger. Exception passed to Log4j as throwable when no other
        #     arguments are provided.
        # @yield [] Return object to be used as the :msg (See Ruby ::Logger). Exceptions
        #    will be used as Throwable arg to log4j.
        #
        # @return [Array<Object, Object, Java::Throwable>] -
        #   Ruby Logger progname, Ruby Logger msg, throwable for log4j
        def convert(object = nil)
          # This implementation is very complex in order to support
          yielded_val = block_given? ? yield : nil

          exception = exception(yielded_val) || exception(object)
          msg = yielded_val || object || exception
          [progname(object, yielded_val), msg, exception&.to_java]
        end

        private

        def progname(object, yielded_val)
          object && yielded_val ? object : nil
        end

        def exception(obj)
          obj.is_a?(::Exception) || obj.is_a?(Java::java.lang.Throwable) ? obj : nil
        end
      end
    end
  end
end
