require 'java'

# Add location of log4j.properties into CLASSPATH
$CLASSPATH << File.dirname(__FILE__) + "/"

$LOAD_PATH << File.dirname(__FILE__) + '/../lib'

require File.dirname(__FILE__) + '/../log4j/log4j-1.2.16.jar'
