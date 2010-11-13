require 'log4jruby'

module Log4jruby
  module Logging
    def self.included(klass)
      def klass.logger
        @logger ||= Logger.new(name)
      end
    end

    def logger
      self.class.logger
    end
  end
end