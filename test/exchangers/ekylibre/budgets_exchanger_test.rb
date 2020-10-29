require 'test_helper'

module Ekylibre
  class BudgetsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::BudgetsExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'budgets.ods')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
