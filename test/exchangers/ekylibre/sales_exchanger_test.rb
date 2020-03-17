require 'test_helper'

module Ekylibre
  class SalesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::SalesExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'sales.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
