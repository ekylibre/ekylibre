require 'test_helper'

module Ekylibre
  class SalesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::SalesExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'sales.csv'))
    end
  end
end
