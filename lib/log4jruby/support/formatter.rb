# frozen_string_literal: true

module Log4jruby
  module Support
    # Default ruby Logger formatter
    # This formatter mimics
    # [Logger::Formatter](https://ruby-doc.org/stdlib-2.6.4/libdoc/logger/rdoc/Logger/Formatter.html)
    # but excludes log level and timestamp to leave it for the Log4j config
    class Formatter
      def call(_severity, _time, progname, msg)
        "-- #{progname}: #{msg}"
      end
    end
  end
end
