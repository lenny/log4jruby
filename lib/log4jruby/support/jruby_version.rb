# frozen_string_literal: true

module Log4jruby
  module Support
    # Class for explicitly marking JRuby version specific code.
    # Find consumers and remove this and references when no longer needed.
    class JrubyVersion
      class << self
        attr_reader :native_ruby_stacktraces_supported

        def native_ruby_stacktraces_supported?
          @native_ruby_stacktraces_supported
        end

        private

        def init
          @native_ruby_stacktraces_supported =
            Gem::Version.new(JRUBY_VERSION) >= Gem::Version.new('9.3')
        end
      end
    end
  end
end

Log4jruby::Support::JrubyVersion.send(:init)
