# frozen_string_literal: true

require 'java'

# Add location of log4j.properties into CLASSPATH
$CLASSPATH << "#{File.dirname(__FILE__)}/"

$LOAD_PATH << "#{File.dirname(__FILE__)}/../lib"

%w(log4j-core-2.18.jar log4j-api-2.18.jar).each do |file|
  require "#{File.dirname(__FILE__)}/../build/java/lib/#{file}"
end

