require 'test_helper'

module Ekylibre
  class EquipmentsJsonExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::EquipmentsJsonExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'equipments_json.json')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
