shared_context 'log capture', :log_capture => true do
  let(:log_capture) { @log_stream.toString }
  
  before do
    @log_stream = Java::java.io.ByteArrayOutputStream.new
    root_log4j_logger = Log4jruby::Logger.root.log4j_logger
    root_log4j_logger.removeAllAppenders
    layout = Java::org.apache.log4j.PatternLayout.new('%5p %.50X{fileName} %X{methodName}:%X{lineNumber} - %m%n')
    appender = Java::org.apache.log4j.WriterAppender.new(layout, @log_stream)
    appender.setImmediateFlush(true)
    root_log4j_logger.addAppender(appender)
  end
end