namespace :test do
  desc 'Run tests for libraries'
  Rails::TestTask.new(lib: 'test:prepare') do |t|
    t.pattern = 'test/lib/**/*_test.rb'
  end

  desc 'Run tests for exchangers'
  Rails::TestTask.new(exchangers: 'test:prepare') do |t|
    t.pattern = 'test/exchangers/**/*_test.rb'
  end

  task javascripts: [:teaspoon]
  task core: ['test:units', 'test:functionals', 'test:lib']

  # Append test for lib
  task run_all: ['test:units', 'test:functionals', 'test:integration', 'test:lib', 'test:javascripts']

  task full: ['test:models', 'test:controllers', 'test:frontend', 'test:libs']

  task frontend: ['test:integration', 'test:javascripts']

  task libs: ['test:helpers', 'test:lib', 'test:exchangers']
end
