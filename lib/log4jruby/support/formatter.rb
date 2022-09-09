# frozen_string_literal: true

module Log4jruby
  module Support
    class Formatter
      def call(severity, time, progname, msg)
        "-- #{progname}: #{msg}"
      end
    end
  end
end