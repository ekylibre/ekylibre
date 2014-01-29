# # Adds special action to do after fixture load
# namespace :db do
#   namespace :test do
#     task :seeds do
#       puts ("=" * 80 ).red
#       puts "Load defaults"
#       puts "count: #{DocumentTemplate.count}"
#       puts "count: #{Entity.count}"
#       DocumentTemplate.load_defaults
#     end
#   end
# end

# Append test for lib
namespace :test do
  desc "Run tests for libraries"
  Rails::TestTask.new(lib: "test:prepare") do |t|
    t.pattern = "test/lib/**/*_test.rb"
  end

  task :core => ['test:units', 'test:functionals', 'test:lib']

  task :run_all => ['test:units', 'test:functionals', 'test:lib', 'test:integration']

  # task :single => "db:test:seeds"
  # task :units => "db:test:seeds"
  # task :functionals => "db:test:seeds"
  # task :integrations => "db:test:seeds"
end

