# Use Lexicon common to load Lexicon directly into Eky
require 'lexicon-common'

module Ekylibre
  class Lexicon
    def initialize
      @factory = ::Lexicon::Common::Database::Factory.new
      @database = @factory.new_instance(url: lexicon_db_url)
      @lexicon_schema_path = Pathname.new(Gem::Specification.find_by_name('lexicon-common').gem_dir).join(::Lexicon::Common::LEXICON_SCHEMA_RELATIVE_PATH)
      @loader = ::Lexicon::Common::Package::DirectoryPackageLoader.new(data_path, schema_validator: ::Lexicon::Common::Schema::ValidatorFactory.new(lexicon_schema_path).build)
    end

    def self.load
      self.new.load
    end

    def load
      puts "Loading Lexicon ...".cyan
      drop_existing_version

      package = if Rails.env.test?
                  load_package('lexicon')
                else
                  download if !File.directory?(data_directory)
                  load_package(version_in_file)
                end

      if package.nil?
        puts 'Error while reading the lexicon package'.red
        raise
      else
        load_package_in_db(package)
      end
    end

    private

      attr_reader :lexicon_schema_path, :loader

      def data_directory
        Rails.root.join('db', 'lexicon', version_in_file)
      end

      def download
        puts "--Download lexicon #{version_in_file}...".cyan
        result = download_lexicon(data_path, loader, version_in_file)
        if result.success?
          puts "[ OK  ] The version #{version_in_file} has been downloaded.".green
        else
          puts '[ NOK ] Error while downloading.'.red
          raise
        end
      rescue Aws::Sigv4::Errors::MissingCredentialsError => e
        puts '[ NOK ] Missing credentials to download from MINIO'.red
        raise
      end

      def load_package(version)
        puts "--Load and validate package...".cyan
        package = loader.load_package(version_in_file)
      end

      def version_in_file
        version = File.open('.lexicon-version', &:gets)&.strip
        puts "No version is mentionned in the .lexicon-version file".red if version.blank?
        version
      rescue
        puts 'The file .lexicon-version is missing'.red
        raise
      end

      # load from db/lexicon on production or development env
      # or from test/fixture-files on test env
      def data_path
        return @data_path if @data_path

        @data_path = if Rails.env.test?
                       Rails.root.join('test', 'fixture-files')
                     else
                       Rails.root.join('db', 'lexicon')
                     end
        unless File.directory?(@data_path)
          FileUtils.mkdir_p(@data_path)
        end
        @data_path
      end

      def drop_existing_version
        puts "--Drop old Lexicon if exist...".cyan
        @database.query("DROP SCHEMA IF EXISTS lexicon CASCADE")
      end

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
end
