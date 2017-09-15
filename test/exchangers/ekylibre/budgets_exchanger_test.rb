require 'test_helper'

module Ekylibre
  class BudgetsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::BudgetsExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'budgets.ods'))
    end
  end
end
