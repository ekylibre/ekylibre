require 'test_helper'

module Isagri
  module Isapaye
    class EcxJournalEntriesExchangerTest < ActiveExchanger::TestCase
      setup do
        FinancialYear.delete_all
        FinancialYear.create! started_on: '2020-01-01', stopped_on: '2020-12-31'
        FinancialYear.create! started_on: '2021-01-01', stopped_on: '2021-12-31'
        I18n.locale = :fra
        Preference.set!(:accounting_system, 'fr_pcga')
        @import = Import.create!(nature: :isagri_isapaye_ecx_journal_entries, creator: User.first)
      end

      test 'import' do
        result = Isagri::Isapaye::EcxJournalEntriesExchanger.build(fixture_files_path.join('imports', 'isagri', 'isapaye', 'ecx_journal_entries.ecr'), options: { import_id: @import.id }).run
        assert result.success?, [result.message, result.exception]
        # check data on balance sheet
        fy = FinancialYear.at(Date.parse('2021-07-31'))
        current_compute = AccountancyComputation.new(fy)
        balance_sheet_balance = current_compute.active_balance_sheet_amount - current_compute.passive_balance_sheet_amount
        assert_equal true, balance_sheet_balance.zero?
      end

      teardown do
        @import.destroy!
      end
    end
  end
end
