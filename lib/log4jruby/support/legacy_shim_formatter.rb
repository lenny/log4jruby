# frozen_string_literal: true

module Log4jruby
  module Support
    # Default ruby Logger formatter for Jruby < 9.3.x
    # This formatter mimics
    # [Logger::Formatter](https://ruby-doc.org/stdlib-2.6.4/libdoc/logger/rdoc/Logger/Formatter.html)
    # but excludes log level and timestamp (delegated to Log4j).
    # It also appends full backtraces with nested causes.
    class LegacyShimFormatter
      def call(_severity, _time, progname, msg)
        "-- #{msg2str(progname)}: #{msg2str(msg)}"
      end

      private

      def msg2str(msg)
        case msg
        when ::String
          msg
        when ::Exception
          exception2str(msg)
        else
          msg.inspect
        end
      end

      def exception2str(exception)
        "#{exception.message} (#{exception.class})\n\t#{exception.backtrace&.join("\n\t")}" \
          "#{"\nCaused by: #{exception2str(exception.cause)}" if exception.cause}"
      end
    end
  end
end
