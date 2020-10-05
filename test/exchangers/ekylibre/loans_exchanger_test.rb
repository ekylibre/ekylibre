require 'test_helper'

module Ekylibre
  class LoansExchangerTest < ActiveExchanger::TestCase

    setup do
      # We want to keep tracking of import resource
      ::I18n.locale = :fra
      @import = Import.create!(nature: :ekylibre_loans, creator: User.first)
      @second_import = Import.create!(nature: :ekylibre_loans, creator: User.first)
    end

    test 'import' do
      result = Ekylibre::LoansExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'loans.csv'), options: { import_id: @import.id }).run
      assert result.success?, [result.message, result.exception]
      lo_count = Loan.all.count
      assert_equal true, lo_count > 1
      second_result = Ekylibre::LoansExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'loans.csv'), options: { import_id: @second_import.id }).run
      assert second_result.success?, [second_result.message, second_result.exception]
      second_lo_count = Loan.all.count
      # check not double object on the same fixed asset by the same provider
      assert_equal true, lo_count == second_lo_count
    end
  end
end
