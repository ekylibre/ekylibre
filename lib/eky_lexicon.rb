# Use Lexicon common to load Lexicon directly into Eky
require 'lexicon-common'

class EkyLexicon
  def initialize
    @factory = ::Lexicon::Common::Database::Factory.new
    @database = @factory.new_instance(url: lexicon_db_url)
  end

  def load
    puts "Loading Lexicon ...".cyan
    @database.query("DROP SCHEMA IF EXISTS lexicon CASCADE")
    puts "--Drop old Lexicon if exist...".cyan
    # load from db/lexicon on production or development env
    # or from test/fixture-files on test env
    if Rails.env.production? || Rails.env.development?
      lexicon_path = Rails.root.join('db', 'lexicon')
      unless File.directory?(lexicon_path)
        FileUtils.mkdir_p(lexicon_path)
      end
    elsif Rails.env.test?
      lexicon_path = Rails.root.join('test', 'fixture-files')
    end

    lexicon_schema_path = Pathname.new(Gem::Specification.find_by_name('lexicon-common').gem_dir).join(::Lexicon::Common::LEXICON_SCHEMA_RELATIVE_PATH)
    loader = ::Lexicon::Common::Package::DirectoryPackageLoader.new(lexicon_path, schema_validator: Lexicon::Common::Schema::ValidatorFactory.new(lexicon_schema_path).build)

    # download on production or development env
    # load on test env
    if Rails.env.production? || Rails.env.development?
      # get version from .lexicon-version
      # create package from db/lexicon/<<version>>
      begin
        version_in_file = File.open('.lexicon-version', &:gets)&.strip
        lexicon_dir = Rails.root.join('db', 'lexicon', version_in_file)
        if lexicon_dir.present? && File.directory?(lexicon_dir)
          puts "--Load and validate package...".cyan
          package = loader.load_package(version_in_file)
        elsif lexicon_dir.present?
          puts "--Download lexicon #{version_in_file}...".cyan
          result = download_lexicon(lexicon_path, loader, version_in_file)
          if result.success?
            puts "[  OK ] The version #{version_in_file} has been downloaded.".green
            puts "--Load and validate package...".cyan
            package = loader.load_package(version_in_file)
          else
            puts '[ NOK ] Error while downloading.'.red
          end
        else
          puts "No version is mentionned in the .lexicon-version".red
        end
      rescue
        puts 'The file .lexicon-version is missing'.red
      end
    elsif Rails.env.test?
      package = loader.load_package('lexicon')
    end

    if package.nil?
      puts 'Error while reading the lexicon package'.red
    else
      load_package_in_db(package)
    end

  end

  private

    ## for lexicon DB connection
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

    def download_lexicon(out_dir, loader, version)
      raw = ::Aws::S3::Client.new(endpoint: ENV.fetch('MINIO_HOST', 'https://io.ekylibre.dev'),
                                access_key_id: ENV.fetch('MINIO_ACCESS_KEY', nil),
                                secret_access_key: ENV.fetch('MINIO_SECRET_KEY', nil),
                                force_path_style: true,
                                region: 'us-east-1')
      s3 = ::Lexicon::Common::Remote::S3Client.new(raw: raw)
      downloader = ::Lexicon::Common::Remote::PackageDownloader.new(s3: s3, out_dir: out_dir, package_loader: loader)
      semver = Semantic::Version.new(version) rescue nil
      downloader.download(semver)
    end

    def load_package_in_db(package)
      executor = ::Lexicon::Common::ShellExecutor.new
      file_loader = ::Lexicon::Common::Production::FileLoader.new(shell: executor, database_url: lexicon_db_url)
      table_locker = ::Lexicon::Common::Production::TableLocker.new(database_factory: @factory, database_url: lexicon_db_url)
      psql = ::Lexicon::Common::Psql.new(url: lexicon_db_url, executor: executor)

      ds_loader = ::Lexicon::Common::Production::DatasourceLoader.new(shell: executor, database_factory: @factory, file_loader: file_loader, database_url: lexicon_db_url, table_locker: table_locker, psql: psql)
      puts "--Load Package in DB...".cyan
      ds_loader.load_package(package)

      puts "--Enable Package as lexicon in DB...".cyan
      @database.query <<~SQL
        BEGIN;
          ALTER SCHEMA "lexicon__#{package.version.to_s.gsub('.', '_')}" RENAME TO "lexicon";
          CREATE TABLE "lexicon"."version" ("version" VARCHAR);
          INSERT INTO "lexicon"."version" VALUES ('#{package.version}');
        COMMIT;
      SQL
      puts 'Lexicon loaded successfully'.green
    end
end
