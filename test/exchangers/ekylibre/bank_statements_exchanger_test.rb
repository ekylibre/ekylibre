require 'test_helper'

module Ekylibre
  class BankStatementsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::BankStatementsExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'bank_statements.ods'))
    end
  end
end
