require 'test_helper'

module Sage
  module Coala
    class FecTxtExchangerTest < ActiveExchanger::TestCase
      setup do
        FinancialYear.delete_all
        FinancialYear.create! started_on: '2020-01-01', stopped_on: '2020-12-31'
        # We want to keep tracking of import resource
        I18n.locale = :fra
        Preference.set!(:accounting_system, 'fr_pcga')
        @import = Import.create!(nature: :sage_coala_fec_txt, creator: User.first)
      end

      test 'import' do
        result = Sage::Coala::FecTxtExchanger.build(fixture_files_path.join('imports', 'sage', 'coala', '2020.txt'), options: { import_id: @import.id }).run
        assert result.success?, [result.message, result.exception]
      end
    end
  end
end
