namespace :backup do

  task :export do
    root = Rails.root

    RAILS_ENV    = ENV['RAILS_ENV'] || 'development'

    config = YAML.load_file(root.join("config", "database.yml"))

    model = Backup::Model.new(:backup, 'Global Backup') do

      archive :app_files do |archive|
        archive.add(root.join("config.ru"))
        archive.add(root.join("Gemfile"))
        archive.add(root.join("Gemfile.lock"))
        archive.add(root.join("Rakefile"))
        archive.add(root.join("VERSION"))
        archive.add(root.join("app"))
        archive.add(root.join("bin"))
        archive.add(root.join("config"))
        archive.add(root.join("db"))
        archive.add(root.join("features"))
        archive.add(root.join("lib"))
        archive.add(root.join("public"))
        archive.add(root.join("test"))
        archive.add(root.join("vendor"))
      end

      archive :private_data do |archive|
        archive.add(root.join("private"))
      end

      archive :variable_files do |archive|
        archive.add(root.join("log"))
        archive.add(root.join("tmp"))
      end

      database Backup::Database::PostgreSQL do |db|
        db.name               = config[RAILS_ENV]["database"]
        db.username           = config[RAILS_ENV]["su_username"]
        db.password           = config[RAILS_ENV]["su_password"]
        db.host               = config[RAILS_ENV]["host"]
        db.port               = config[RAILS_ENV]["port"]
        db.skip_tables        = []
        db.additional_options = config[RAILS_ENV]["schema_search_path"].split(/[\,\s]+/).collect{|n| "-n #{n}" }
      end

      compress_with Backup::Compressor::Gzip do |compression|
        compression.best = true
        compression.fast = false
      end

      store_with Backup::Storage::Local do |local|
        local.path = root
        local.keep = 10
      end

    end

    model.perform!

  end

end

task :backup => "backup:export"
