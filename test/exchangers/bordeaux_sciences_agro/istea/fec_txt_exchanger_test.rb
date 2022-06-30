require 'test_helper'

module BordeauxSciencesAgro
  module Istea
    class FecTxtExchangerTest < ActiveExchanger::TestCase
      setup do
        FinancialYear.delete_all
        FinancialYear.create! started_on: '2020-01-01', stopped_on: '2020-12-31'
        Preference.set!(:accounting_system, 'fr_pcga')
        # We want to keep tracking of import resource
        I18n.locale = :fra
        @import = Import.create!(nature: :bordeaux_sciences_agro_istea_fec_txt, creator: User.first)
      end

      test 'import' do
        result = BordeauxSciencesAgro::Istea::FecTxtExchanger.build(fixture_files_path.join('imports', 'bordeaux_sciences_agro', 'istea', '123456789FEC20201231.txt'), options: { import_id: @import.id }).run
        assert result.success?, [result.message, result.exception]
        # check baance after import
        fy = FinancialYear.at(Date.parse('2020-01-01'))
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
