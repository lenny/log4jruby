# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.

require 'java'
require 'spec/autorun'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
#Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

$LOAD_PATH << File.dirname(__FILE__) + '/../lib'

require File.dirname(__FILE__) + '/../log4j/log4j-1.2.16.jar'

Spec::Runner.configure do |config|

end
