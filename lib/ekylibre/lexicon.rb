# Use Lexicon common to load Lexicon directly into Eky
require 'lexicon-common'

module Ekylibre
  class Lexicon
    def initialize(target_version = nil)
      @test_mode = Rails.env.test?
      @target_version = target_version || version_in_file
      @current_version = LexiconVersion.version || nil
      @factory = ::Lexicon::Common::Database::Factory.new
      @database = @factory.new_instance(url: lexicon_db_url)
      @lexicon_schema_path = Pathname.new(Gem::Specification.find_by_name('lexicon-common').gem_dir).join(::Lexicon::Common::LEXICON_SCHEMA_RELATIVE_PATH)
      @loader = ::Lexicon::Common::Package::DirectoryPackageLoader.new(data_path, schema_validator: ::Lexicon::Common::Schema::ValidatorFactory.new(lexicon_schema_path).build)
    end

    # test mode
    # target_version from file present in test/fixtures-files/lexicon
    # remove old lexicon, load and activate evenif already present
    def self.load_for_test
      self.new.load_for_test
    end

    # dev mode, don't check anythink
    # target_version from file .lexicon-version
    # remove existing lexicon evenif already present, download, load and activate.
    def self.load(enable = true, keep_lexicon_versions = false)
      self.new.load(enable, keep_lexicon_versions)
    end

    # prod mode, check if lexicon is not in DB and if version is not already enabled
    # version_name from params LEX_VERSION
    # download only
    def self.download(version_name)
      self.new(version_name).load(false, true)
    end

    # prod mode, check if lexicon is in DB and if version is not already enabled
    # version_name from params LEX_VERSION, keep_lexicon_versions from params KEEP
    # activate only
    def self.activate(version_name, keep_lexicon_versions = false)
      self.new(version_name).enable_version(keep_lexicon_versions)
    end

    def load(enable, keep_lexicon_versions)
      if @current_version.present? && @current_version == @target_version
        error("Lexicon #{@target_version} is already loaded and activated.")
      elsif check_version_in_db == 1
        error("Lexicon #{@target_version} is already loaded. You must activated it")
      else
        info("Loading Lexicon ...")
        if keep_lexicon_versions == false
          info("Drop existing version in DB ...")
          drop_existing_version
        end
        package = if @test_mode
                    load_package('lexicon')
                  else
                    if File.directory?(data_directory)
                      info("Lexicon files for #{@target_version} already present in #{data_path.to_s}")
                    else
                      info("Missing files for #{@target_version}. Downloading in #{data_path.to_s}...")
                      download
                      info("Files donwloaded for #{@target_version}")
                    end
                    info("Check package ...")
                    load_package
                  end

        if package.nil?
          error('Error while reading the lexicon package')
        else
          load_package_in_db(package, enable)
        end
      end
    end

    def load_for_test
      unless @test_mode
        error('You must use this method only in test mode')
      end
      drop_existing_version
      package = load_package('lexicon')
      if package.nil?
        error('Error while reading the lexicon package')
      else
        load_package_in_db(package, true)
      end
    end

    def enable_version(keep_lexicon_versions)
      # if lexicon already loaded && activated
      if @current_version.present? && @current_version == @target_version
        info("Lexicon #{@target_version} is already loaded and activated.")
      # if lexicon already loaded but not activated
      elsif check_version_in_db == 1
        info("Lexicon #{@target_version} is present in DB.")
        # if annother lexicon already activated
        if @current_version.present?
          if keep_lexicon_versions == false
            info("Drop existing version #{@current_version} from DB ...")
            drop_existing_version
          else
            info("Disabled existing version #{@current_version} but keep in DB ...")
            disable_old_version_in_db
          end
        else
          drop_existing_version
        end
        enable_version_in_db
      else
        error("Lexicon #{@target_version} is not loaded.")
      end
    end

    private

      attr_reader :lexicon_schema_path, :loader

      def data_directory
        Rails.root.join('db', 'lexicon', @target_version)
      end

      def download
        info("Download lexicon #{@target_version}...")
        result = download_lexicon(data_path, loader, semantic_version)
        if result.success?
          success("The version #{@target_version} has been downloaded.")
        else
          error("Error while downloading : #{result.error.message}")
        end
      rescue Aws::Sigv4::Errors::MissingCredentialsError => e
        error('Missing credentials to download from MINIO')
      end

      def load_package(version_to_load = nil)
        version_to_load ||= @target_version
        info("Load and validate package...")
        package = loader.load_package(version_to_load)
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

      def semantic_version
        semver = Semantic::Version.new(@target_version)
      rescue
        error("Version #{@target_version} doesn't exist")
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

      def enable_package_in_db(package)
        info("Enable Package as lexicon in DB...")
        @database.query <<~SQL
          BEGIN;
            ALTER SCHEMA "lexicon__#{package.version.to_s.gsub('.', '_')}" RENAME TO "lexicon";
            CREATE TABLE "lexicon"."version" ("version" VARCHAR);
            INSERT INTO "lexicon"."version" VALUES ('#{package.version}');
          COMMIT;
        SQL
        success("#{package.version.to_s} is enabled.")
      end

      # return 1 if schema present or 0 if not
      def check_version_in_db
        info("Check if #{@target_version} is already loaded in DB...")
        present_in_db = @database.query "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name = 'lexicon__#{@target_version.to_s.gsub('.', '_')}'"
        present_in_db.to_a.first["count"].to_i
      end

      def enable_version_in_db
        info("Enable #{@target_version} as lexicon in DB...")
        @database.query <<~SQL
          BEGIN;
            ALTER SCHEMA "lexicon__#{@target_version.to_s.gsub('.', '_')}" RENAME TO "lexicon";
            CREATE TABLE "lexicon"."version" ("version" VARCHAR);
            INSERT INTO "lexicon"."version" VALUES ('#{@target_version}');
          COMMIT;
        SQL
        success("#{@target_version} is enabled.")
      end

      def disable_old_version_in_db
        info("Disable #{@current_version} as lexicon in DB...")
        @database.query <<~SQL
          BEGIN;
            DELETE TABLE "lexicon"."version";
            ALTER SCHEMA "lexicon" RENAME TO "lexicon__#{@current_version.to_s.gsub('.', '_')}";
          COMMIT;
        SQL
        success("#{@current_version} is disabled.")
      end

      def load_package_in_db(package, enable = false)
        info("Load package in DB with option enable : #{enable.to_s}...")
        executor = ::Lexicon::Common::ShellExecutor.new
        file_loader = ::Lexicon::Common::Production::FileLoader.new(shell: executor, database_url: lexicon_db_url)
        table_locker = ::Lexicon::Common::Production::TableLocker.new(database_factory: @factory, database_url: lexicon_db_url)
        psql = ::Lexicon::Common::Psql.new(url: lexicon_db_url, executor: executor)
        ds_loader = ::Lexicon::Common::Production::DatasourceLoader.new(shell: executor, database_factory: @factory, file_loader: file_loader, database_url: lexicon_db_url, table_locker: table_locker, psql: psql)
        ds_loader.load_package(package)
        if @test_mode
          success("#{package.version.to_s} is loaded.")
          enable_package_in_db(package) if enable == true
        else
          success("#{@target_version} is loaded.")
          enable_version_in_db if enable == true
        end
      end
  end
end
