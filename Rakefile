require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :dev do
  desc 'install development java deps'
  task :java_deps do
    sh 'mvn dependency:resolve && mvn dependency:copy@java-libs'
  end
end
