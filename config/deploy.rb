# config valid only for current version of Capistrano
lock '3.9.1'

set :application, 'ekylibre'
set :repo_url, 'git@gitlab.com:ekylibre-integration/larrere.git'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
append :linked_files, 'config/database.yml', 'config/secrets.yml', 'config/application.yml', 'config/tenants.yml'

# Default value for linked_dirs is []
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system', 'tmp/archives', 'private'

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }
set :default_env, 'JAVA_HOME' => '/usr/lib/jvm/java-8-openjdk-amd64'

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :rails_env, 'production'

namespace :deploy do
  after :published, :restart_daemons do |_host|
    on roles(:app) do
      execute :sudo, :service, "#{fetch(:application)}-job", :restart
    end
    on roles(:web) do
      execute :sudo, :service, "#{fetch(:application)}-web", :restart
    end
  end

  before :updated, 'yarn:install'
  # before :updated, 'yarn:build'
end

namespace :yarn do
  desc 'Install yarn dependencies'
  task :install do
    on roles(:app) do
      within release_path do
        execute :yarn, :install, '--ignore-engines'
      end
    end
  end

  desc 'yarn dependencies'
  task :build do
    on roles(:app) do
      within release_path do
        with node_env: :production do
          execute :yarn, :build
        end
      end
    end
  end
end
