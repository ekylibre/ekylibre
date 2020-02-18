Rake::Task['test:run'].clear

namespace :test do
  parts = [
    :concepts,
    :controllers,
    :exchangers,
    :helpers,
    :jobs,
    :lib,
    :models,
    :services,
    # misc
     :validators#, :decorators, :javascripts
  ]

  task prepare: 'lexicon:load'

  parts.each do |p|
    full_task_name = "test:#{p}"
    Rake::Task[full_task_name].clear if Rake::Task.task_defined? full_task_name

    Rails::TestTask.new(p) do |t|
      t.pattern = "test/#{p}/**/*_test.rb"
    end

    desc "Ekylibre tests for #{p}"
    task p => 'test:prepare'
  end

  task all: parts #[*parts, :javascripts, :api]

  # desc 'Run tests for api'
  Rails::TestTask.new(api: 'test:prepare') do |t|
    t.pattern = 'test/controllers/api/v1/**/*_test.rb'
  end
end

task :test => 'test:prepare'
