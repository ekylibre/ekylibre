namespace :test do
  desc 'Runs the plugins tests.'
  task :plugins do
    Rake::Task['test:plugins:all'].invoke
  end

  namespace :plugins do
    desc 'Runs the plugins all tests.'
    Rake::TestTask.new all: 'db:test:prepare' do |t|
      t.libs << 'test'
      t.verbose = true
      t.pattern = "plugins/#{ENV['PLUGIN'] || ENV['NAME'] || '*'}/test/{models,controllers,mailers,jobs,integration,helpers,lib}/**/*_test.rb"
    end

    desc 'Runs the plugins model tests.'
    Rake::TestTask.new models: 'db:test:prepare' do |t|
      t.libs << 'test'
      t.verbose = true
      t.pattern = "plugins/#{ENV['PLUGIN'] || ENV['NAME'] || '*'}/test/models/**/*_test.rb"
    end

    desc 'Runs the plugins helper tests.'
    Rake::TestTask.new helpers: 'db:test:prepare' do |t|
      t.libs << 'test'
      t.verbose = true
      t.pattern = "plugins/#{ENV['PLUGIN'] || ENV['NAME'] || '*'}/test/helpers/**/*_test.rb"
    end

    desc 'Runs the plugins units test'
    task units: %i[models helpers]

    desc 'Runs the plugins controller tests.'
    Rake::TestTask.new controllers: 'db:test:prepare' do |t|
      t.libs << 'test'
      t.verbose = true
      t.pattern = "plugins/#{ENV['PLUGIN'] || ENV['NAME'] || '*'}/test/controllers/**/*_test.rb"
    end

    desc 'Runs the plugins mailers tests.'
    Rake::TestTask.new mailers: 'db:test:prepare' do |t|
      t.libs << 'test'
      t.verbose = true
      t.pattern = "plugins/#{ENV['PLUGIN'] || ENV['NAME'] || '*'}/test/mailers/**/*_test.rb"
    end

    desc 'Runs the plugins functionals test'
    task functionals: %i[controllers mailers]

    desc 'Runs the plugins integration tests.'
    Rake::TestTask.new integration: 'db:test:prepare' do |t|
      t.libs << 'test'
      t.verbose = true
      t.pattern = "plugins/#{ENV['PLUGIN'] || ENV['NAME'] || '*'}/test/integration/**/*_test.rb"
    end

    desc 'Runs the plugins jobs tests.'
    Rake::TestTask.new jobs: 'db:test:prepare' do |t|
      t.libs << 'test'
      t.verbose = true
      t.pattern = "plugins/#{ENV['PLUGIN'] || ENV['NAME'] || '*'}/test/jobs/**/*_test.rb"
    end

    desc 'Runs the plugins lib tests.'
    Rake::TestTask.new jobs: 'db:test:prepare' do |t|
      t.libs << 'test'
      t.verbose = true
      t.pattern = "plugins/#{ENV['PLUGIN'] || ENV['NAME'] || '*'}/test/lib/**/*_test.rb"
    end
  end
end

# Load plugins rake tasks
Dir[File.join(Rails.root, 'plugins/*/lib/tasks/**/*.rake')].sort.each { |ext| load ext }
