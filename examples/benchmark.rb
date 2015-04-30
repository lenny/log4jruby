require File.dirname(__FILE__) + '/setup'

require 'log4jruby'
require 'benchmark'

Log4jruby::Logger.root.log4j_logger.removeAllAppenders
$out = File.open('/dev/null', 'a')

formatter = Class.new do
  def call(severity, time, name, msg)
    msg
  end
end.new

root_logger = Log4jruby::Logger.root
log4j = root_logger.log4j_logger
std_logger = ::Logger.new($out)
logger_a = Log4jruby::Logger.get('a')
logger_a_b = Log4jruby::Logger.get('a.b')
logger_c = Log4jruby::Logger.get('c', tracing: true)
logger_d = Log4jruby::Logger.get('d', formatter: formatter)

root_logger.debug('warmup')

repeat = 200000

puts "Benchmark with #{repeat} log statements"

Benchmark.bmbm do |x|
  x.report('puts')   { (1..repeat).each { |i| $out.puts(i) } }
  x.report('standard logger')   { (1..repeat).each { |i| std_logger.debug(i) } }
  x.report('raw log4j') { (1..repeat).each { |i| log4j.debug(i) } }
  x.report('root') { (1..repeat).each { |i| root_logger.debug(i) }}
  x.report('a')  { (1..repeat).each { |i| logger_a.debug(i) }}
  x.report('a.b')  { (1..repeat).each { |i| logger_a_b.debug(i) }}
  x.report('w. tracing')  { (1..repeat).each { |i| logger_c.debug(i) }}
  x.report('w. formatter')  { (1..repeat).each { |i| logger_d.debug(i) }}
end

$out.close
