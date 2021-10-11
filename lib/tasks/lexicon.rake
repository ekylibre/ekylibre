# Tenant tasks
namespace :lexicon do
  require 'lexicon-common'

  desc 'Load a lexicon from db/lexicon folder mentionned in .lexicon-version file'
  task load: :environment do
    # use gem lexicon-common
    puts "Loading Lexicon ...".cyan

    factory = ::Lexicon::Common::Database::Factory.new
    database = factory.new_instance(url: lexicon_db_url)
    database.query("DROP SCHEMA IF EXISTS lexicon CASCADE")
    puts "--Drop old Lexicon if exist...".cyan

    lexicon_path = Rails.root.join('db', 'lexicon')
    lexicon_schema_path = Pathname.new(Gem::Specification.find_by_name('lexicon-common').gem_dir).join(::Lexicon::Common::LEXICON_SCHEMA_RELATIVE_PATH)

    loader = ::Lexicon::Common::Package::DirectoryPackageLoader.new(lexicon_path, schema_validator: Lexicon::Common::Schema::ValidatorFactory.new(lexicon_schema_path).build)
    puts "--Load and validate package...".cyan

    # get version from .lexicon-version
    # create package from db/lexicon/<<version>>
    begin
      version_in_file = File.open('.lexicon-version', &:gets)&.strip
      lexicon_dir = Rails.root.join('db', 'lexicon', version_in_file)
      if lexicon_dir.present? && File.directory?(lexicon_dir)
        package = loader.load_package(version_in_file)
      elsif lexicon_dir.present?
        puts "The folder lexicon #{version_in_file} is missing".red
      else
        puts "No version is mentionned in the .lexicon-version".red
      end
    rescue
      puts 'The file .lexicon-version is missing'.red
    end

    if package.nil?
      puts 'Error while reading the lexicon package'.red
    else
      executor = ::Lexicon::Common::ShellExecutor.new
      file_loader = ::Lexicon::Common::Production::FileLoader.new(shell: executor, database_url: lexicon_db_url)
      table_locker = ::Lexicon::Common::Production::TableLocker.new(database_factory: factory, database_url: lexicon_db_url)
      psql = ::Lexicon::Common::Psql.new(url: lexicon_db_url, executor: executor)

      ds_loader = ::Lexicon::Common::Production::DatasourceLoader.new(shell: executor, database_factory: factory, file_loader: file_loader, database_url: lexicon_db_url, table_locker: table_locker, psql: psql)
      puts "--Load Package in DB...".cyan
      ds_loader.load_package(package)

      puts "--Enable Package as lexicon in DB...".cyan
      database.query <<~SQL
        BEGIN;
          ALTER SCHEMA "lexicon__#{package.version.to_s.gsub('.', '_')}" RENAME TO "lexicon";
          CREATE TABLE "lexicon"."version" ("version" VARCHAR);
          INSERT INTO "lexicon"."version" VALUES ('#{package.version}');
        COMMIT;
      SQL
      puts 'Lexicon loaded successfully'.green
    end
  end

  private

    ## for lexicon
    def lexicon_db_url
      user = db_config['username']
      host = db_config['host']
      port = db_config['port'] || '5432'
      dbname = db_config['database']
      password = db_config['password']
      URI.encode("postgresql://#{user}:#{password}@#{host}:#{port}/#{dbname}")
    end

    def db_config
      Rails.application.config.database_configuration[Rails.env.to_s]
    end

end
