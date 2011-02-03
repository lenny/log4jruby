# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name = "log4jruby"
  s.version = '0.1.dev'

  s.authors = ["Lenny Marks"]
  s.email = ["lenny@aps.org"]
  s.summary = "Ruby Logger using Log4j, geared toward those who use JRuby to write Ruby code using/extending Java code. Ruby and Java are configured together using traditional Log4j methods."
  s.description= <<-END
  Log4jruby is a thin wrapper around the Log4j Logger. It is geared more toward 
  those who are using JRuby to integrate with and build on top of Java code that 
  uses Log4j. The Log4jruby::Logger provides an interface much like the standard 
  ruby Logger. Your ruby loggers are given a .jruby prefix and can be configured 
  along with the loggers for your Java code.
  END
  s.files = Dir.glob("{lib, spec}/**/*") + %w(README.rdoc History.txt)
  s.extra_rdoc_files = ["README.rdoc"]

  s.homepage = "https://github.com/lenny/log4jruby"
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  
  s.add_development_dependency("rspec", [">= 1.3.1"])

end
