require 'test_helper'

class UnitComputationTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  setup do
    @pnv = create(:phytosanitary_variant,
                  unit_name: 'hl',
                  default_unit_name: 'liter',
                  default_unit_id: Unit.find_by(reference_name: 'liter').id,
                  default_quantity: 100)
    @pnv.readings.find_by(indicator_name: :net_volume).update(measure_value_value: 100)
    @hl_unit = Unit.import_from_lexicon(:hl)
  end

  test "#convert_into_variant_population" do
    value = UnitComputation.convert_into_variant_population(@pnv, 10, @hl_unit)
    assert_equal 10.to_f, value
  end

  test "#convert_into_variant_default_unit" do
    value = UnitComputation.convert_into_variant_default_unit(@pnv, 10, @hl_unit)
    assert_equal 1_000.to_f, value
  end
end
