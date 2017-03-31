require 'test_helper'

module Ekylibre
  class CultivableZonesJsonExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::CultivableZonesJsonExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'cultivable_zones_json.json'))
    end

    test 'import 3D' do
      Ekylibre::CultivableZonesJsonExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'cultivable_zones_json_2.json'))
    end
  end
end
