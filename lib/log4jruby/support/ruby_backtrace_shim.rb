# frozen_string_literal: true

module Log4jruby
  module Support
    # Transform exceptions into string with full backtraces and nested causes.
    module RubyBacktraceShim
      class << self
        def adapt(msg)
          return msg unless msg.is_a?(::Exception)

          exception2str(msg)
        end

        private

        def exception2str(exception)
          "#{exception.message} (#{exception.class})\n\t#{exception.backtrace&.join("\n\t")}" \
            "#{"\nCaused by: #{exception2str(exception.cause)}" if exception.cause}"
        end
      end
    end
  end
end
