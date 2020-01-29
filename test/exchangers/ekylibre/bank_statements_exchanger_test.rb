require 'test_helper'

module Ekylibre
  class BankStatementsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::BankStatementsExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'bank_statements.ods')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
