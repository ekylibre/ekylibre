require 'test_helper'

module Agrigest
  class FecTxtExchangerTest < ActiveExchanger::TestCase
    setup do
      FinancialYear.delete_all
      FinancialYear.create! started_on: '2022-04-01', stopped_on: '2023-03-31', accounting_system: 'fr_pcga'
      Preference.set!(:accounting_system, 'fr_pcga')
      # We want to keep tracking of import resource
      I18n.locale = :fra
      @import = Import.create!(nature: :agrigest_fec_txt, creator: User.first)
    end

    test 'import' do
      result = Agrigest::FecTxtExchanger.build(fixture_files_path.join('imports', 'agrigest', '123456789FEC20230331.txt'), options: { import_id: @import.id }).run
      assert result.success?, [result.message, result.exception]
      # check baance after import
      fy = FinancialYear.at(Date.parse('2022-04-01'))
      current_compute = AccountancyComputation.new(fy)
      balance_sheet_balance = current_compute.active_balance_sheet_amount - current_compute.passive_balance_sheet_amount
      assert_equal true, balance_sheet_balance.zero?
    end

    teardown do
      @import.destroy!
    end
  end
end
