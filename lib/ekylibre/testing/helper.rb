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
        Ekylibre::Lexicon.load

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

        def db_config
          Rails.application.config.database_configuration[Rails.env.to_s]
        end

        def setup_factories
          ::FactoryBot.find_definitions
        end
    end
  end
end
