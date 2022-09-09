module Log4jruby
  module Support
    class JrubyVersion
      class << self
        def native_ruby_stacktraces_supported?
          Gem::Version.new(JRUBY_VERSION) >= Gem::Version.new('9.3')
        end
      end
    end
  end
end
