require 'test_helper'

module Quadra
  class FecTxtExchangerTest < ActiveExchanger::TestCase

    setup do
      FinancialYear.delete_all
      FinancialYear.create! started_on: '2018-08-01', stopped_on: '2019-07-31'
      # We want to keep tracking of import resource
      I18n.locale = :fra
      Preference.set!(:accounting_system, 'fr_pcg82')
      @import = Import.create!(nature: :quadra_fec_txt, creator: User.first)
    end

    test 'import' do
      result = Quadra::FecTxtExchanger.build(fixture_files_path.join('imports', 'quadra', '123456789FEC20190731.txt'), options: { import_id: @import.id }).run
      assert result.success?, [result.message, result.exception]
      # check data on balance sheet
      fy = FinancialYear.at(Date.parse('2018-08-01'))
      current_compute = AccountancyComputation.new(fy)
      balance_sheet_balance = current_compute.active_balance_sheet_amount - current_compute.passive_balance_sheet_amount
      assert_equal true, balance_sheet_balance.zero?
    end

  end
end
