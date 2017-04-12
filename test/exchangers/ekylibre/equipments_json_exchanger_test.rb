require 'test_helper'

module Ekylibre
  class EquipmentsJsonExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::EquipmentsJsonExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'equipments_json.json'))
    end
  end
end
