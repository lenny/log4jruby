
module Log4jruby::Support
  module LoggerSilencer
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def silence(temporary_level = ::Logger::ERROR)
        begin
          old_logger_level, self.level = level, temporary_level
          yield self
        ensure
          self.level = old_logger_level
        end
      end
    end
  end
end