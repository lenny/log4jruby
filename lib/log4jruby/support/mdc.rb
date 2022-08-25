# frozen_string_literal: true

module Log4jruby
  module Support
    # Utility methods for interacting with Log4j
    # MDC (mapped diagnostic contexts)
    # https://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/MDC.html
    class Mdc
      class << self
        def with_context # :nodoc:
          file_line_method = parse_caller(caller(3).first)
          mdc_put(file_line_method)
          begin
            yield
          ensure
            mdc_remove
          end
        end

        private

        def mdc_put(file_line_method)
          mdc.put('fileName', file_line_method[0])
          mdc.put('lineNumber', file_line_method[1])
          mdc.put('methodName', file_line_method[2].to_s)
        end

        def mdc_remove
          mdc.remove('fileName')
          mdc.remove('lineNumber')
          mdc.remove('methodName')
        end

        def parse_caller(at) # :nodoc:
          at.match(/^(.+?):(\d+)(?::in `(.*)')?/).captures
        end

        def mdc
          Java::org.apache.logging.log4j.ThreadContext
        end
      end
    end
  end
end
