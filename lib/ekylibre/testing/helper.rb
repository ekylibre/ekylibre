module Ekylibre
  module Testing
    class Helper
      include ::Ekylibre::Testing::Concerns::LocaleSetter

      def setup
        configure_locale

        setup_tenants
        setup_database_cleaner
        setup_factories

        setup_timestamp_format
        reload_lexicon

        # TODO: reactivate this when we have a rails version compatible (5.2/6.0)
        # setup_minitest_reporters
      end

      private

        def setup_timestamp_format
          ApplicationRecord.connection.execute <<~SQL
            ALTER DATABASE "#{db_config['database']}" SET intervalstyle='iso_8601';
          SQL
        end

        def setup_minitest_reporters
          Minitest::Reporters.use!(
            # Disable this as Rails uses its own reporter that does not handle well replacement ones
            # (ENV['CI'] ? Minitest::Reporters::DefaultReporter.new : Ekylibre::Testing::SpecReporter.new),
            ENV,
            Minitest.backtrace_filter
          )
        end

        def configure_locale
          # Allows to test locales
          reset_locale
          puts "Locale set to #{::I18n.locale.to_s.green}".yellow
        end

        def setup_tenants
          puts "Setup tenant: #{'sekindovall'.green}".yellow
          ::Ekylibre::Tenant.setup!('sekindovall')

          puts "Setup tenant: #{'test_without_fixtures'.green}".yellow
          ::Ekylibre::Tenant.setup!('test_without_fixtures')

          puts "Setup tenant: #{'test'.green}".yellow
          ::Ekylibre::Tenant.setup!('test', keep_files: true)
        end

        def setup_database_cleaner
          # ::Ekylibre::Tenant.switch 'test_without_fixtures' do
          #   puts "Cleaning tenant: #{'test_without_fixtures'.green}".yellow
          #   ::DatabaseCleaner.clean_with(
          #     :truncation,
          #     {
          #       except: [
          #         'spatial_ref_sys',
          #         "master_legal_positions",
          #         "registered_phytosanitary_cropsets",
          #         "registered_phytosanitary_products",
          #         "registered_phytosanitary_risks",
          #         "registered_phytosanitary_usages",
          #         "master_variant_natures",
          #         "master_variant_categories",
          #         "master_variants",
          #         "registered_hydrographic_items"
          #       ]
          #     }
          #   )
          # end

          ::DatabaseCleaner.strategy = :transaction
        end

        def reload_lexicon
          # use gem lexicon-common
          puts "Loading Lexicon ...".cyan

          factory = ::Lexicon::Common::Database::Factory.new
          database = factory.new_instance(url: lexicon_db_url)
          database.query("DROP SCHEMA IF EXISTS lexicon CASCADE")
          puts "--Drop old Lexicon if exist...".cyan

          lexicon_path = Rails.root.join('test', 'fixture-files')
          lexicon_schema_path = Pathname.new(Gem::Specification.find_by_name('lexicon-common').gem_dir).join(::Lexicon::Common::LEXICON_SCHEMA_RELATIVE_PATH)

          loader = ::Lexicon::Common::Package::DirectoryPackageLoader.new(lexicon_path, schema_validator: Lexicon::Common::Schema::ValidatorFactory.new(lexicon_schema_path).build)
          puts "--Load and validate package...".cyan
          package = loader.load_package('lexicon')

          if package.nil?
            puts 'Error while reading the lexicon package'
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
          end

          puts 'Lexicon loaded successfully'.green
        end

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

        def setup_factories
          ::FactoryBot.find_definitions
        end
    end
  end
end
