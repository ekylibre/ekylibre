class UpdateAnimalGroupPopulationCounting < ActiveRecord::Migration
  PRODUCT_NATURES = %w[
    bee_band
    bumblebee_band
    cattle_herd
    duck_band
    duck_herd
    female_adult_cattle_herd
    female_adult_goat_herd
    female_adult_sheep_herd
    goat_herd
    hen_band
    hen_herd
    horse_herd
    male_adult_goat_herd
    oyster_band
    pig_band
    pig_herd
    piglet_band
    rabbit_herd
    salmon_band
    sheep_herd
  ].freeze

  def up
    execute "UPDATE product_natures SET population_counting = 'unitary' WHERE reference_name IN (#{PRODUCT_NATURES.map { |v| quote(v) }.join(', ')})"
  end

  def down
    execute "UPDATE product_natures SET population_counting = 'integer' WHERE reference_name IN (#{PRODUCT_NATURES.map { |v| quote(v) }.join(', ')})"
  end
end
