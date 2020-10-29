require 'test_helper'

module Ekylibre
  class GeoreadingsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::GeoreadingsExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'georeadings.zip')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
