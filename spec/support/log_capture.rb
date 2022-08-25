# frozen_string_literal: true

shared_context 'log capture', log_capture: true do
  let(:log_stream) { Java::java.io.ByteArrayOutputStream.new }
  let(:log_capture) { log_stream.toString }

  before do
    layout = Java::org.apache.logging.log4j.core.layout.PatternLayout.newBuilder
                 .withPattern('%5p %.50X{fileName} %X{methodName}:%X{lineNumber} - %m%n').build
    appender = Java::org.apache.logging.log4j.core.appender.OutputStreamAppender
                   .newBuilder.setName('memory')
                   .setImmediateFlush(true)
                   .withLayout(layout).setTarget(log_stream).build
    # log4j2 logger attributes are inherited from config only
    # i.e. loggers will not inherit properties from private config on rootLogger
    root_config = Java::org.apache.logging.log4j.LogManager.rootLogger.get
    root_config.clearAppenders
    root_config.level = Java::org.apache.logging.log4j.Level::DEBUG
    root_config.addAppender(appender, nil, nil)
  end
end
