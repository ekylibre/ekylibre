require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the simple_localization plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

namespace :test do
  
  desc 'Run all core tests of the simple_localization plugin.'
  Rake::TestTask.new(:core) do |t|
    t.libs << 'lib'
    t.pattern = 'test/core/**/*_test.rb'
    t.verbose = true
  end
  
  desc 'Run all feature tests of the simple_localization plugin.'
  Rake::TestTask.new(:features) do |t|
    t.libs << 'lib'
    t.pattern = 'test/features/**/*_test.rb'
    t.verbose = true
  end
  
end

desc 'Generate documentation for the simple_localization plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'SimpleLocalization'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
