require 'test_helper'

module Accountancy
  module Cfonb
    class ImporterTest < Ekylibre::Testing::ApplicationTestCase
      setup do
        @importer = Importer.build
        create :cash, iban: 'FR8314508000309837485442I87'
      end

      test 'import working' do
        import = @importer.import_bank_statement(file_path("import_cfonb.csv"))
        assert import.success?

        bank_statement = import.value
        bank_statement_items = bank_statement.items

        assert_equal [DateTime.new(2020, 7, 31), DateTime.new(2020, 9, 1)], [bank_statement.started_on, bank_statement.stopped_on]

        assert_equal 3, bank_statement_items.count

        assert_equal [DateTime.new(2020, 8, 3), DateTime.new(2020, 8, 5), DateTime.new(2020, 8, 6)], bank_statement_items.map(&:transfered_on)

        assert_equal [-50_000.0, 54.96, -200.0], bank_statement_items.map(&:balance)

        assert bank_statement_items.any?(&:memo)

        assert_equal "credit_draw", bank_statement_items.first.transaction_nature
      end

      test 'import failing because multiple accounts' do
        import = @importer.import_bank_statement(file_path('import_cfonb_multiple_account_numbers.csv'))

        assert import.failure?
        assert_equal "multiple_account_numbers", import.error.message
      end

      test 'import failing because content is not cfonb' do
        import = @importer.import_bank_statement(file_path('import_cfonb_wrong_content.csv'))

        assert import.failure?
        assert_equal "invalid_uploaded_file", import.error.message
      end

      test 'import failing because no cash in database matches cfonb cash ' do
        import = @importer.import_bank_statement(file_path('import_cfonb_no_matching_cash.csv'))

        assert import.failure?
        assert_equal "no_cash_found_for_account", import.error.message
      end

      private

        # @param [String] file
        # @return [Pathname]
        def file_path(file)
          Pathname.new('test/fixture-files/accountancy/cfonb').join(file)
        end
    end
  end
end
