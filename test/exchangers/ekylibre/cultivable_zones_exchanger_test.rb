require 'test_helper'

module Ekylibre
  class CultivableZonesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::CultivableZonesExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'cultivable_zones.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
