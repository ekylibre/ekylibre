namespace :test do
  desc "Run tests for libraries"
  Rails::TestTask.new(lib: "test:prepare") do |t|
    t.pattern = "test/lib/**/*_test.rb"
  end

  task :core => ['test:units', 'test:functionals', 'test:lib']

  # Append test for lib
  task :run_all => ['test:units', 'test:functionals', 'test:lib', 'test:integration']
end

