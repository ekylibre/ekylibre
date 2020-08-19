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

    Rails::TestTask.new(p) do |t|
      t.pattern = "test/#{p}/**/*_test.rb"
    end
  end

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
    desc "Run tests in edited test files"
    task :git do
      puts "No test file to run!".red
    end
  else
    # GIT test task
    Rails::TestTask.new(:git) do |t|
      t.test_files = files
    end
  end

end
