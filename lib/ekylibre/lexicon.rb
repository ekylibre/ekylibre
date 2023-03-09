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
      info("Loading Lexicon ...")
      drop_existing_version
      package = if Rails.env.test?
                  load_package('lexicon')
                else
                  download if !File.directory?(data_directory)
                  load_package(version_in_file)
                end

      if package.nil?
        error('Error while reading the lexicon package')
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
        version = version_in_file
        info("Download lexicon #{version}...")
        result = download_lexicon(data_path, loader, semantic_version(version))
        if result.success?
          success("The version #{version} has been downloaded.")
        else
          error("Error while downloading : #{result.error.message}")
        end
      rescue Aws::Sigv4::Errors::MissingCredentialsError => e
        error('Missing credentials to download from MINIO')
      end

      def load_package(version)
        info("Load and validate package...")
        package = loader.load_package(version)
      end

      def version_in_file
        version = File.open('.lexicon-version', &:gets)&.strip
        if version.blank?
          error( "No version is mentionned in the .lexicon-version file")
        end
        version
      rescue
        error('The file .lexicon-version is missing')
      end

      def semantic_version(version)
        semver = Semantic::Version.new(version)
      rescue
        error("Version #{version} doesn't exist")
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
        info("Drop old Lexicon if exist...")
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

      def download_lexicon(out_dir, loader, semantic_version)
        raw = ::Aws::S3::Client.new(endpoint: ENV.fetch('MINIO_HOST', 'https://io.ekylibre.dev'),
                                  access_key_id: ENV.fetch('MINIO_ACCESS_KEY', nil),
                                  secret_access_key: ENV.fetch('MINIO_SECRET_KEY', nil),
                                  force_path_style: true,
                                  region: 'us-east-1')
        s3 = ::Lexicon::Common::Remote::S3Client.new(raw: raw)
        downloader = ::Lexicon::Common::Remote::PackageDownloader.new(s3: s3, out_dir: out_dir, package_loader: loader)
        downloader.download(semantic_version)
      end

      def info(message)
        puts "-- #{message}".cyan
      end

      def success(message)
        puts "[ OK ] #{message}".green
      end

      def error(message)
        puts "[ NOK ] #{message}".red
        exit(false)
      end

      def load_package_in_db(package)
        executor = ::Lexicon::Common::ShellExecutor.new
        file_loader = ::Lexicon::Common::Production::FileLoader.new(shell: executor, database_url: lexicon_db_url)
        table_locker = ::Lexicon::Common::Production::TableLocker.new(database_factory: @factory, database_url: lexicon_db_url)
        psql = ::Lexicon::Common::Psql.new(url: lexicon_db_url, executor: executor)

        ds_loader = ::Lexicon::Common::Production::DatasourceLoader.new(shell: executor, database_factory: @factory, file_loader: file_loader, database_url: lexicon_db_url, table_locker: table_locker, psql: psql)
        info("Load Package in DB...")
        ds_loader.load_package(package)

        info("Enable Package as lexicon in DB...")
        @database.query <<~SQL
          BEGIN;
            ALTER SCHEMA "lexicon__#{package.version.to_s.gsub('.', '_')}" RENAME TO "lexicon";
            CREATE TABLE "lexicon"."version" ("version" VARCHAR);
            INSERT INTO "lexicon"."version" VALUES ('#{package.version}');
          COMMIT;
        SQL
        success('Lexicon loaded successfully')
      end
  end
end
