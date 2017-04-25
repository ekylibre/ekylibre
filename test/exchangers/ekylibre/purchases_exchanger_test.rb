require 'test_helper'

module Ekylibre
  class PurchasesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::PurchasesExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'purchases.csv'))
    end
  end
end
