require 'test_helper'

module Ekylibre
  class CultivableZonesJsonExchangerTest < ::ActiveExchanger::TestCase
    test 'import' do
      ::ActiveExchanger::Base.import(:ekylibre_cultivable_zones_json, fixture_files_path.join('imports', 'ekylibre_cultivable_zones_json.json'))
    end
    test 'import 3D' do
      ::ActiveExchanger::Base.import(:ekylibre_cultivable_zones_json, fixture_files_path.join('imports', 'ekylibre_cultivable_zones_json_2.json'))
    end
  end
end
