# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'capybara/version'

Gem::Specification.new do |s|
  s.name = "log4jruby"
  s.version = '0.1.0'

  s.authors = ["Lenny Marks"]
  s.email = ["lenny@aps.org"]
  s.summary = "Logging via Log4j using interface that looks like Ruby's standard Logger. Java and Ruby configured together."
  s.description = File.read(File.dirname(__FILE__) + "/README.rdoc")

  s.files = Dir.glob("{lib, spec}/**/*") + %w(README.rdoc History.txt)
  s.extra_rdoc_files = ["README.rdoc"]

  s.homepage = "https://github.com/lenny/log4jruby"
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  
  s.add_development_dependency("rspec", [">= 1.3.1"])

end
