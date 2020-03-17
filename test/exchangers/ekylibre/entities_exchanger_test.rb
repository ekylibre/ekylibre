require 'test_helper'

module Ekylibre
  class EntitiesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::EntitiesExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'entities.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
