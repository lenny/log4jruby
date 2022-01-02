module Log4jruby
  module Support
    class Log4jArgs
      class << self

        # Adapt permutations of ruby Logger arguments into arguments
        # for Log4j Logger with explicit throwable when possible.
        #
        # Treats arguments as strings when given unexpected types.
        #
        # @param object [String | Exception] - Correlates to the `progname` arg of ruby Logger.
        #                                      Exception passed to Log4j as throwable when no other
        #                                      arguments are provided.
        # @param throwable [Exception] - Log4J Throwable. Will be logged as part
        #                                of Log4j message when given unexpected type.
        # @yield [] Return string or Exception. Exception will be used as Log4j
        #           throwable when no other argments are provided or as part of
        #           message otherwise.
        # @return [Array<String, Java::Throwable>]
        def convert(object = nil, throwable = nil)
          # This implementation is very complex in order to support
          # all the potential argument permutations gracefully.
          yielded_val = block_given? ? yield : nil

          progname, log4j_throwable, msg_parts = nil, nil, []

          if exception?(throwable)
            progname = object
            log4j_throwable = throwable
            msg_parts << yielded_val
          else
            if exception?(object) && throwable.nil? && yielded_val.nil?
              log4j_throwable = object
              msg_parts.concat([yielded_val])
            else
              progname = object
              if exception?(yielded_val) && object.nil? && throwable.nil?
                log4j_throwable = yielded_val
                msg_parts.concat([throwable])
              else
                msg_parts.concat([throwable, yielded_val])
              end
            end
          end

          [build_msg(progname, msg_parts, log4j_throwable), log4j_throwable.to_java]
        end

        private

        def exception?(o)
          o.is_a?(::Exception) || o.is_a?(Java::java.lang.Throwable)
        end

        def build_msg(progname, msg_parts, throwable)
          filtered_parts = msg_parts.compact
          effective_progname = progname.nil? && throwable ? throwable.message : progname

          return effective_progname.to_s if filtered_parts.empty?

          effective_progname.nil? ?
            "#{filtered_parts.join(' ')}" :
            "#{effective_progname}: #{filtered_parts.join(' ')}"
        end
      end
    end
  end
end
