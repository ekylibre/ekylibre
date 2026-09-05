# Use Lexicon common to load Lexicon directly into Eky
require 'lexicon-common'
require 'net/http'
require 'uri'

module Ekylibre
  class Lexicon
    # Duck-typed Aws::S3::Client for anonymous HTTP read on public S3-compatible
    # buckets (MinIO, AWS S3 with public-read policy). Used by `download_lexicon`
    # when MINIO_ACCESS_KEY/MINIO_SECRET_KEY are not set, so a self-hosted prod
    # can fetch the lexicon without sharing Ekylibre's internal credentials.
    #
    # Implements only the methods called during a download:
    #   - `head_bucket(bucket:)` for `Lexicon::Common::Remote::S3Client#bucket_exist?`
    #   - `get_object(bucket:, key:, response_target:)` for `PackageDownloader`
    class AnonymousHttpS3Client
      MAX_REDIRECTS = 3

      def initialize(endpoint:)
        normalized = endpoint.to_s.chomp('/')
        @endpoint_uri = URI.parse(normalized)
      end

      # Mimics Aws::S3::Client#head_bucket — returns truthy on 200, raises on error.
      def head_bucket(bucket:)
        request_with_redirects(bucket_uri(bucket), method: :head) { |_resp| }
        true
      end

      # Mimics Aws::S3::Client#get_object — streams the body to `response_target`.
      def get_object(bucket:, key:, response_target:)
        FileUtils.mkdir_p(File.dirname(response_target))
        request_with_redirects(object_uri(bucket, key), method: :get) do |response|
          File.open(response_target, 'wb') do |io|
            response.read_body { |chunk| io.write(chunk) }
          end
        end
      end

      private

        def bucket_uri(bucket)
          URI.join("#{@endpoint_uri}/", "#{bucket}/")
        end

        def object_uri(bucket, key)
          URI.join("#{@endpoint_uri}/", "#{bucket}/#{key}")
        end

        def request_with_redirects(uri, method:, redirects_left: MAX_REDIRECTS, &block)
          raise "Too many redirects fetching #{uri}" if redirects_left.negative?

          Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
            request_class = method == :head ? Net::HTTP::Head : Net::HTTP::Get
            http.request(request_class.new(uri.request_uri)) do |response|
              case response.code.to_i
              when 200..299
                yield response
              when 301, 302, 303, 307, 308
                new_uri = URI.parse(response['location'])
                new_uri = URI.join(uri, new_uri) unless new_uri.absolute?
                return request_with_redirects(new_uri, method: method, redirects_left: redirects_left - 1, &block)
              else
                raise "HTTP #{response.code} for #{method.upcase} #{uri}"
              end
            end
          end
        end
    end

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

    # Drop a downloaded but not-activated lexicon schema (lexicon__X_Y_Z).
    # Refuses to drop the currently active `lexicon` schema.
    def self.remove(version_name)
      self.new(version_name).remove_version
    end

    # Return list of versions already downloaded in the database
    # (lexicon__X_Y_Z schemas), excluding the active `lexicon` schema.
    def self.loaded_versions
      self.new.loaded_versions
    end

    # Return list of available bucket names on MinIO matching the given prefix.
    # Requires MINIO_ACCESS_KEY / MINIO_SECRET_KEY — without credentials, listing
    # buckets is not allowed by S3 and an empty array is returned.
    def self.available_versions(prefix: nil)
      endpoint   = ENV.fetch('MINIO_HOST', 'https://io.ekylibre.tech')
      access_key = ENV['MINIO_ACCESS_KEY'].to_s
      secret_key = ENV['MINIO_SECRET_KEY'].to_s

      return [] if access_key.empty? || secret_key.empty?

      client = ::Aws::S3::Client.new(
        endpoint: endpoint,
        access_key_id: access_key,
        secret_access_key: secret_key,
        force_path_style: true,
        region: 'us-east-1'
      )
      names = client.list_buckets.buckets.map(&:name)
      names = names.select { |n| n.start_with?(prefix) } if prefix
      names.sort
    rescue StandardError
      []
    end

    def loaded_versions
      result = @database.query <<~SQL
        SELECT schema_name FROM information_schema.schemata
        WHERE schema_name ~ '^lexicon__'
        ORDER BY schema_name
      SQL
      result.to_a.map do |row|
        name = row['schema_name'].sub(/^lexicon__/, '')
        prefix, dash, suffix = name.partition('-')
        prefix.gsub('_', '.') + dash + suffix
      end
    rescue StandardError
      []
    end

    def remove_version
      schema = "lexicon__#{@target_version.to_s.gsub('.', '_')}"
      if @current_version.present? && @current_version == @target_version
        raise "Cannot drop the currently active lexicon version (#{@target_version}). Activate another version first."
      end
      @database.query("DROP SCHEMA IF EXISTS \"#{schema}\" CASCADE")
    end

    def load(enable, keep_lexicon_versions)
      if @current_version.present? && @current_version == @target_version
        info("Lexicon #{@target_version} is already loaded and activated.")
      elsif check_version_in_db == 1
        info("Lexicon #{@target_version} is already loaded. You must activated it")
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
        raw = build_remote_client
        s3 = ::Lexicon::Common::Remote::S3Client.new(raw: raw)
        downloader = ::Lexicon::Common::Remote::PackageDownloader.new(s3: s3, out_dir: out_dir, package_loader: loader)
        downloader.download(semantic_version)
      end

      def build_remote_client
        endpoint = ENV.fetch('MINIO_HOST', 'https://io.ekylibre.tech')
        access_key = ENV['MINIO_ACCESS_KEY'].to_s
        secret_key = ENV['MINIO_SECRET_KEY'].to_s

        if access_key.empty? || secret_key.empty?
          info("MINIO credentials not set — using anonymous HTTP download (public buckets only).")
          AnonymousHttpS3Client.new(endpoint: endpoint)
        else
          ::Aws::S3::Client.new(endpoint: endpoint,
                              access_key_id: access_key,
                              secret_access_key: secret_key,
                              force_path_style: true,
                              region: 'us-east-1')
        end
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
        Ekylibre::Tenant.grant_read_only_access('lexicon')
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
        Ekylibre::Tenant.grant_read_only_access('lexicon')
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
