require 'test_helper'

module Ekylibre
  class LandParcelsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::LandParcelsExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'land_parcels.csv'))
    end
  end
end
