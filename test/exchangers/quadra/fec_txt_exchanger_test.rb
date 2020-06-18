require 'test_helper'

module Quadra
  class FecTxtExchangerTest < ActiveExchanger::TestCase

    setup do
      FinancialYear.delete_all
      FinancialYear.create! started_on: '2018-08-01', stopped_on: '2019-07-31'
      # We want to keep tracking of import resource
      I18n.locale = :fra
      @import = Import.create!(nature: :quadra_fec_txt, creator: User.first)
    end

    test 'import' do
      result = Quadra::FecTxtExchanger.build(fixture_files_path.join('imports', 'quadra', '123456789FEC20190731.txt'), options: { import_id: @import.id }).run
      assert result.success?, [result.message, result.exception]
      # check data on balance sheet
      fy = FinancialYear.at(Date.parse('2018-08-01'))
      document_scope = :balance_sheet
      current_compute = AccountancyComputation.new(fy)
      entities_reserve_value = current_compute.sum_entry_items_by_line(document_scope, :entities_reserve)
      debts_cashe_debts_total_value = current_compute.sum_entry_items_by_line(document_scope, :debts_cashe_debts_total)
      assert_equal 299934.85, entities_reserve_value.to_f
      assert_equal 389429.97, debts_cashe_debts_total_value.to_f
    end

  end
end
