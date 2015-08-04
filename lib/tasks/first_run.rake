# First-runs tasks
namespace :first_run do
  desc 'Load the default first-run'
  task default: :environment do
    ENV['name'] ||= ENV['TENANT']
    Ekylibre::FirstRun.launch!({ folder: 'default' }.merge(ENV.to_hash.symbolize_keys.slice(:folder, :name, :max, :mode, :verbose, :path)))
  end
end

desc 'Load first run in one transaction'
task first_run: :environment do
  Ekylibre::FirstRun.launch! ENV.to_hash.symbolize_keys.slice(:folder, :name, :max, :mode, :verbose, :path)
end
