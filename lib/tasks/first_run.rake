# First-runs tasks
namespace :first_run do

  desc "Build a First-Run package"
  task :build do
    folder = ENV["folder"]
    Ekylibre::FirstRun.build(folder)
  end

end

desc "Execute first run in one transaction"
task :first_run => :environment do
  Ekylibre::FirstRun.launch ENV.to_hash.symbolize_keys.slice(:folder, :name, :max, :mode)
  # Workaround for public schema tables disappearance
  Rake::Task["db:schema:load"].invoke
end
