namespace :test do
  additional_tests = %w[lib exchangers services concepts]
  additional_tests.each do |name|
    task name => 'test:prepare' do
      $LOAD_PATH << 'test'
      Rails::TestUnit::Runner.rake_run(["test/#{name}"])
    end
  end

  task javascripts: [:teaspoon]
  task core: ['test:units', 'test:functionals', 'test:lib']

  Rake::Task['test:run'].enhance additional_tests.map { |t| "test:#{t}"}
  Rake::Task['test:functionals'].enhance %w[test:services test:concepts test:exchangers]

  # Append test for lib
  task run_all: ['test:units', 'test:functionals', 'test:integration', 'test:lib', 'test:javascripts']

  task full: ['test:models', 'test:controllers', 'test:frontend', 'test:libs']

  task frontend: ['test:integration', 'test:javascripts']

  task libs: ['test:helpers', 'test:lib', 'test:exchangers', 'test:services', 'test:concepts', 'test:jobs']
end
