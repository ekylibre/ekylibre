# First-runs tasks
require 'ekylibre/first_run'
namespace :first_run do
  namespace :default do
    task generate: :environment do
      dir = Ekylibre::FirstRun.path.join('default')
      FileUtils.mkdir_p dir.to_s
      manifest = {
        revision: 1,
        host: 'default.ekylibre.localhost',
        demo: false,
        currency: 'EUR',
        language: 'fra',
        country: 'fr',
        company: {
          addresses: {
            mail: {
              line_6: '33600 PESSAC'
            }
          }
        },
        users: {
          'admin@ekylibre.org' => {
            first_name: 'Duke',
            last_name: 'Doe',
            password: '12345678'
          }
        }
      }
      File.write(dir.join('manifest.yml'), manifest.deep_stringify_keys.to_yaml)
    end
  end

  desc 'Load the default first-run'
  task default: :environment do
    # Accept uppercase env vars (as documented in CLAUDE.md). PATH is excluded
    # because it is reserved for the shell command lookup path.
    %w[folder name max mode verbose].each { |k| ENV[k] ||= ENV[k.upcase] }
    ENV['name'] ||= ENV['TENANT']
    unless Ekylibre::FirstRun.path.join('default').exist?
      Rake::Task['first_run:default:generate'].invoke
    end
    Ekylibre::FirstRun.launch!({ folder: 'default' }.merge(ENV.to_hash.symbolize_keys.slice(:folder, :name, :max, :mode, :verbose, :path)))
  end
end

desc 'Load first run in one transaction'
task first_run: :environment do
  # Accept uppercase env vars (as documented in CLAUDE.md). PATH is excluded
  # because it is reserved for the shell command lookup path.
  %w[folder name max mode verbose].each { |k| ENV[k] ||= ENV[k.upcase] }
  ENV['name'] ||= ENV['TENANT']
  ENV['mode'] ||= 'hard' if ENV['HARD'].to_s.downcase == 'true'
  Ekylibre::FirstRun.launch! ENV.to_hash.symbolize_keys.slice(:folder, :name, :max, :mode, :verbose, :path)
end
