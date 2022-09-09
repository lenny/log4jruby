# frozen_string_literal: true

module Log4jruby
  module Support
    class LegacyShimFormatter
      def call(severity, time, progname, msg)
        "-- #{msg2str(progname)}: #{msg2str(msg)}"
      end

      private

      def msg2str(msg)
        case msg
        when ::String
          msg
        when ::Exception
          stringify_exception_chain(msg)
        else
          msg.inspect
        end
      end

      def stringify_exception_chain(exception)
        if exception.cause
          "#{stringify_exception(exception)}\nCaused by: #{stringify_exception_chain(exception.cause)}"
        else
          stringify_exception(exception)
        end
      end

      def stringify_exception(exception)
        "#{ exception.message } (#{ exception.class })\n\t#{ exception.backtrace&.join("\n\t")}"
      end
    end
  end
end