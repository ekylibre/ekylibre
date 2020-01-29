require 'test_helper'

module Ekylibre
  class LandParcelsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::LandParcelsExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'land_parcels.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
