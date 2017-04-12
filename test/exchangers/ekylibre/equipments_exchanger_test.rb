require 'test_helper'

module Ekylibre
  class EquipmentsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::EquipmentsExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'equipments.csv'))
    end
  end
end
