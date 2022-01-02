# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'log4jruby/version'

Gem::Specification.new do |gem|
  gem.name          = 'log4jruby'
  gem.version       = Log4jruby::VERSION
  gem.authors       = ['Lenny Marks']
  gem.email         = ['lenny@aps.org']
  gem.description   = %q{Ruby Logger using Log4j, geared toward those who use JRuby to write Ruby code using/extending Java code. Ruby and Java are configured together using traditional Log4j methods.}
  gem.summary       = <<-END
  Log4jruby is a thin wrapper around the Log4j Logger. It is geared more toward 
  those who are using JRuby to integrate with and build on top of Java code that 
  uses Log4j. The Log4jruby::Logger provides an interface much like the standard 
  ruby Logger. Your ruby loggers are given a .jruby prefix and can be configured 
  along with the loggers for your Java code.
  END

  gem.homepage      = 'https://github.com/lenny/log4jruby'

  gem.files         = Dir.glob('{lib, spec}/**/*') + %w(README.md CHANGELOG.md)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
  gem.platform = 'java'
  gem.license = 'MIT'

  # jruby >= 9.3.0.0
  gem.required_ruby_version = '~> 2.6.8'
end
