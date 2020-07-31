FactoryBot.define do
  factory :product_nature do
    sequence(:name) { |n| "Cultivable Zone #{n}" }
    population_counting { 'unitary' }
    variety { 'cultivable_zone' }
  end

  factory :worker_nature, parent: :product_nature do
    variety { 'worker' }
  end

  factory :plants_nature, class: ProductNature do
    sequence(:name) { |n| "Plant nature - TEST#{n.to_s.rjust(8, '0')}" }
    population_counting { :unitary }
    variety { :plant }
    variable_indicators_list { [:shape] }
    frozen_indicators_list { [:net_surface_area] }
  end

  factory :deliverable_nature, class: ProductNature do
    sequence(:name) { |n| "Seed #{n}" }
    population_counting { :integer }
    variety { 'seed' }
  end

  factory :services_nature, class: ProductNature do
    sequence(:name) { |n| "Service #{n}" }
    population_counting { :integer }
    variety { 'service' }
  end

  factory :animals_nature, class: ProductNature do
    sequence(:name) { |n| "Animal #{n}" }
    population_counting { :integer }
    variety { 'animal' }
  end

  factory :equipment_nature, class: ProductNature do
    sequence(:name) { |n| "Equipment nature - TEST#{n.to_s.rjust(8, '0')}" }
    population_counting { :unitary }
    variety { :tractor }
  end

  factory :building_division_nature, class: ProductNature do
    sequence(:name) { |n| "Building division nature - #{n}" }
    population_counting { 'unitary' }
    variety { 'building_division' }
  end

  factory :fertilizer_nature, class: ProductNature do
    sequence(:name) { |n| "Fertilizer - TEST#{n.to_s.rjust(8, '0')}" }
    population_counting { :decimal }
    variety { 'preparation' }
    variable_indicators_list { %i[approved_input_dose untreated_zone_length wait_before_entering_period] }
    frozen_indicators_list { %i[net_mass net_volume wait_before_harvest_period] }
  end

  factory :phytosanitary_nature, class: ProductNature do
    sequence(:name) { |n| "Plant Medicine - TEST#{n.to_s.rjust(8, '0')}" }
    population_counting { :decimal }
    variety { 'preparation' }
    reference_name { 'plant_medicine' }
    frozen_indicators_list { %i[approved_input_dose, net_mass, net_volume, untreated_zone_length, wait_before_entering_period, wait_before_harvest_period] }
  end

  factory :tractor_nature, class: ProductNature do
    sequence(:name) { |n| "Tractor nature - #{n}" }
    population_counting { :unitary }
    variety { :tractor }
    abilities_list { %w[catch(equipment) tow(equipment) move] }
    variable_indicators_list { %i[hour_counter] }
  end

  factory :sower_nature, class: ProductNature do
    sequence(:name) { |n| "Sower nature - #{n}" }
    population_counting { :unitary }
    variety { :trailed_equipment }
    abilities_list { %w[sow] }
  end

  factory :seed_nature, class: ProductNature do
    sequence(:name) { |n| "Seed nature - #{n}" }
    population_counting { :decimal }
    variety { :seed }
    derivative_of { :plant }
    reference_name { :seed }

    abilities_list { %w[grow] }

    frozen_indicators_list { %i[grains_count net_mass thousand_grains_mass] }
  end

  factory :harvest_nature, class: ProductNature do
    sequence(:name) { |n| "Harvesting nature - #{n}" }
    population_counting { :decimal }
    variety { :vegetable }
    derivative_of { :plant }

    frozen_indicators_list { %i[net_mass] }
  end

  factory :land_parcel_nature, class: ProductNature do
    sequence(:name) { |n| "Land parcel nature - #{n}" }
    population_counting { :decimal }
    variety { :land_parcel }
    variable_indicators_list { [:shape] }
    frozen_indicators_list { [:net_surface_area] }
  end

  factory :plant_medicine_nature, class: ProductNature do
    sequence(:name) { |n| "Plant medicine - TEST#{n.to_s.rjust(8, '0')}" }
    population_counting { :decimal }
    variety { 'preparation' }
    reference_name { 'plant_medicine' }
    frozen_indicators_list { %i[approved_input_dose, net_mass, net_volume, untreated_zone_length, wait_before_entering_period, wait_before_harvest_period] }
  end
end
