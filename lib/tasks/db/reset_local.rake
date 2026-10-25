namespace :db do
  desc 'Reset the test database for local dev (workaround for kartoza/postgis schema conflicts). Test env only.'
  task reset_local: :environment do
    abort "db:reset_local only runs with RAILS_ENV=test (got #{Rails.env.inspect})" unless Rails.env.test?

    cfg = Rails.application.config.database_configuration[Rails.env]
    db = cfg.fetch('database')
    host = cfg['host'].to_s
    user = cfg.fetch('username')
    password = cfg['password'].to_s
    port = cfg['port'].to_s

    psql = lambda do |sql:, on_error_stop: true, file: nil|
      args = ['psql']
      args += ['-h', host] unless host.empty?
      args += ['-p', port] unless port.empty?
      args += ['-U', user, '-d', db, '-v', 'ON_ERROR_STOP=1'] if on_error_stop
      args += ['-U', user, '-d', db] unless on_error_stop
      args += ['-c', sql] if sql
      args += ['-f', file] if file
      env = { 'PGPASSWORD' => password }
      ok = system(env, *args)
      raise "psql failed (#{args.last(2).join(' ')})" if on_error_stop && !ok
    end

    ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK'] = '1'

    puts "Drop database #{db.inspect}".yellow
    Rake::Task['db:drop'].invoke

    puts "Create database #{db.inspect}".yellow
    Rake::Task['db:create'].invoke

    puts 'Drop auto-created public schema (postgis schema/extension are kept — installed by db:extensions)'.yellow
    psql.call(sql: 'DROP SCHEMA IF EXISTS public CASCADE;')

    structure_path = Rails.root.join('db', 'structure.sql')
    puts "Load #{structure_path} (without ON_ERROR_STOP — the duplicate CREATE SCHEMA postgis is benign)".yellow
    psql.call(sql: nil, on_error_stop: false, file: structure_path.to_s)

    puts 'Load lexicon'.yellow
    Rake::Task['lexicon:load'].invoke

    puts 'db:reset_local done'.green
  end
end
