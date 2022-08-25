# frozen_string_literal: true

require 'logger'

module Log4jruby
  module Support
    # Internal class for tracking loggers in a thread safe manor
    class LogManager
      @loggers = {}
      @mutex = Mutex.new.freeze
      @logger_class = nil

      class << self
        def configure(logger_class:)
          @logger_class = logger_class
        end

        def get_or_create(name)
          raise 'name required' if name.to_s.match?(/^\s+$/)

          @mutex.synchronize do
            @loggers[name] ||= new_logger(name)
          end
        end

        def get(name)
          @mutex.synchronize { @loggers[name] }
        end

        # nodoc: testing only
        def reset
          @mutex.synchronize { @loggers.clear }
          Java::org.apache.logging.log4j.LogManager.rootLogger.context.stop
        end

        def root
          get_or_create('jruby')
        end

        def parent(name)
          _parent(name.split('.'))
        end

        private

        def new_logger(name)
          log4j_logger = Java::org.apache.logging.log4j.LogManager.getLogger(name)
          @logger_class.new(log4j_logger)
        end

        def _parent(name_path)
          return root if name_path.empty?

          parent_path = name_path[0, name_path.size - 1]
          parent_name = parent_path.join('.')

          get(parent_name) || _parent(parent_path)
        end
      end
    end
  end
end


