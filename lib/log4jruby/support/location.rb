# frozen_string_literal: true

module Log4jruby
  module Support
    # Utility methods for interacting with Log4j
    # MDC (mapped diagnostic contexts)
    # https://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/MDC.html
    class Location
      class << self
        def with_location # :nodoc:
          file_line_method = parse_caller(caller(3).first)
          context_put(file_line_method)
          begin
            yield
          ensure
            context_remove
          end
        end

        private

        def context_put((file, line, method))
          thread_context.put('fileName', file)
          thread_context.put('lineNumber', line)
          thread_context.put('methodName', method.to_s)
        end

        def context_remove
          thread_context.remove('fileName')
          thread_context.remove('lineNumber')
          thread_context.remove('methodName')
        end

        def parse_caller(at) # :nodoc:
          at.match(/^(.+?):(\d+)(?::in `(.*)')?/).captures
        end

        def thread_context
          Java::org.apache.logging.log4j.ThreadContext
        end
      end
    end
  end
end
