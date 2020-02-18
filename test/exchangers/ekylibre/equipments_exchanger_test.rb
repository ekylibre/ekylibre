require 'test_helper'

module Ekylibre
  class EquipmentsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::EquipmentsExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'equipments.csv')).run
      assert result.success?, [result.message, result.exception]

      cuve_1 = Product.find_by name: 'Cuve n°1'
      refute_nil cuve_1
      assert_equal 1, cuve_1.population
    end

    test 'import fails if population is not 1 and counting_unitary' do
      result = Ekylibre::EquipmentsExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'equipments_invalid.csv')).run

      assert result.error?
    end
  end
end
