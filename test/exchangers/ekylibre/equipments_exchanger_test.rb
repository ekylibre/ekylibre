require 'test_helper'

module Ekylibre
  class EquipmentsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::EquipmentsExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'equipments.csv'))

      cuve_1 = Product.find_by name: 'Cuve n°1'
      refute_nil cuve_1
      assert_equal 1, cuve_1.population
    end

    test 'import fails if population is not 1 and counting_unitary' do
      assert_raise(StandardError) do
        Ekylibre::EquipmentsExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'equipments_invalid.csv'))
      end
    end
  end
end
