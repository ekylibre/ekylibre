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

        setup_minitest_reporters
      end

      private

        def setup_timestamp_format
          db_config = Rails.application.config.database_configuration[Rails.env.to_s]

          ApplicationRecord.connection.execute <<~SQL
            ALTER DATABASE "#{db_config['database']}" SET intervalstyle='iso_8601';
          SQL
        end

        def setup_minitest_reporters
          Minitest::Reporters.use!(
            (ENV['CI'] ? Minitest::Reporters::DefaultReporter.new : Ekylibre::Testing::SpecReporter.new),
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
          #         "registered_legal_positions",
          #         "registered_phytosanitary_cropsets",
          #         "registered_phytosanitary_products",
          #         "registered_phytosanitary_risks",
          #         "registered_phytosanitary_usages",
          #         "variant_natures",
          #         "variant_categories",
          #         "variants",
          #         "registered_hydro_items"
          #       ]
          #     }
          #   )
          # end

          ::DatabaseCleaner.strategy = :transaction
        end

        def reload_lexicon
          puts "Loading Lexicon ...".cyan

          factory = Lexicon::Database::Factory.from_rails_config
          database = factory.new_instance
          database.query("DROP SCHEMA IF EXISTS lexicon CASCADE")

          loader = Lexicon::Package::DirectoryPackageLoader.new(Rails.root.join('test', 'fixture-files'), schema_validator: Lexicon::FakeValidator.new)
          package = loader.load_package('lexicon')

          if package.nil?
            puts 'Error while reading the lexicon package'
          else
            executor = Lexicon::ShellExecutor.new
            # executor.logger = Rails.logger

            ds_loader = Lexicon::Production::DatasourceLoader.new(shell: executor, database_factory: factory)
            ds_loader.load_package(package)

            database.query <<~SQL
              BEGIN;
                ALTER SCHEMA "lexicon__#{package.version.to_s.gsub('.', '_')}" RENAME TO "lexicon";
                CREATE TABLE "lexicon"."version" ("version" VARCHAR);
                INSERT INTO "lexicon"."version" VALUES ('#{package.version}');
              COMMIT;
            SQL
          end

          puts '[  OK ] Lexicon loaded successfully'.green
        end

        def setup_factories
          ::FactoryBot.find_definitions
        end
    end
  end
end
