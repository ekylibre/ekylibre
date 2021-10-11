require 'test_helper'

class ConditioningValidatable
  include ActiveModel::Validations
  attr_accessor :unit, :variant

  def initialize(variant:)
    @variant = variant
  end

  validates :unit, conditioning: true

  def dimension
    unit.dimension
  end

  def of_dimension?(dimension)
    unit.of_dimension?(dimension)
  end
end

class ConditioningValidatorTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  setup do
    variant_in_mass = create :seed_variant
    @obj = ConditioningValidatable.new(variant: variant_in_mass)
  end

  test "record passes the validations if its unit and its variant's default_unit belong to the same dimension" do
    mass_unit = Unit.find_by_reference_name(:kilogram)
    @obj.unit = mass_unit

    assert @obj.valid?
  end

  test "record doesn't pass the validations if its unit and its variant's default_unit don't belong to the same dimension" do
    volume_unit = Unit.find_by_reference_name(:liter)
    @obj.unit = volume_unit

    refute @obj.valid?
  end
end
