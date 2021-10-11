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
    :validators # , :decorators, :javascripts
  ]

  parts.each do |p|
    full_task_name = "test:#{p}"
    Rake::Task[full_task_name].clear if Rake::Task.task_defined? full_task_name

    desc "Test #{full_task_name}"
    task p => 'test:prepare' do
      $LOAD_PATH << 'test'
      Rails::TestUnit::Runner.rake_run(["test/#{p}"])
    end
  end

  # GIT test task
  desc "Run tests in edited test files"
  task :git do
    $LOAD_PATH << 'test'
    files = begin
              Git.open(Rails.root, log: Rails.logger)
                 .diff(ENV.fetch('BASE', 'core'))
                 .select { |f| %w(new modified).include?(f.type) }
                 .select { |f| f.path =~ %r{\Atest/.*?_test\.rb\z} }
                 .map(&:path)
                 .select { |p| Rails.root.join(p).exist? }
            rescue StandardError
              []
            end
    if files.empty?
      puts "No test file to run!".red
    else
      Rails::TestUnit::Runner.rake_run(["test/#{p}"])
    end
  end
end
