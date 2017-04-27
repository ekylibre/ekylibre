require 'test_helper'

module Ekylibre
  class GeoreadingsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::GeoreadingsExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'georeadings.zip'))
    end
  end
end
