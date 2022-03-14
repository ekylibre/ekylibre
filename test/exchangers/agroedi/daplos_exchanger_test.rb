require 'test_helper'

module Agroedi
  class DaplosExchangerTest < ActiveExchanger::TestCase
    setup do
      I18n.locale = :fra
      FinancialYear.delete_all
      FinancialYear.create! started_on: '2020-01-01', stopped_on: '2020-12-31'
      FinancialYear.create! started_on: '2021-01-01', stopped_on: '2021-12-31'
      @import = Import.create!(nature: :agroedi_daplos, creator: User.first)
    end

    test 'import' do
      result = Agroedi::DaplosExchanger.build(fixture_files_path.join('imports', 'agroedi', 'intervention_daplos.dap'), options: { import_id: @import.id }).run
      assert result.success?, [result.message, result.exception]
    end

    teardown do
      @import.destroy!
    end
  end
end
