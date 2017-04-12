require 'test_helper'

module Ekylibre
  class CultivableZonesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::CultivableZonesExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'cultivable_zones.csv'))
    end
  end
end
