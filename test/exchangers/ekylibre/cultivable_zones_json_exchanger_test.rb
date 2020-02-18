require 'test_helper'

module Ekylibre
  class CultivableZonesJsonExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::CultivableZonesJsonExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'cultivable_zones_json.json')).run
      assert result.success?, [result.message, result.exception]
    end

    test 'import 3D' do
      result = Ekylibre::CultivableZonesJsonExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'cultivable_zones_json_2.json')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
