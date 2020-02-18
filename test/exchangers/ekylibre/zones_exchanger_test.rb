require 'test_helper'

module Ekylibre
  class ZonesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::ZonesExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'zones.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
