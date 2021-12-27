require 'java'

# Add location of log4j.properties into CLASSPATH
$CLASSPATH << File.dirname(__FILE__) + "/"

$LOAD_PATH << File.dirname(__FILE__) + '/../lib'

require File.dirname(__FILE__) + '/../build/java/lib/log4j-1.2.jar'
