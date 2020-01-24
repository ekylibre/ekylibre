FactoryBot.define do
  factory :product_nature do
    sequence(:name)     { |n| "Cultivable Zone #{n}" }
    population_counting { 'unitary' }
    variety             { 'cultivable_zone' }

    association         :category, factory: :product_nature_category

    factory :land_parcel_nature do
      variety { 'land_parcel' }
      variable_indicators_list { [:shape] }
      frozen_indicators_list   { [:net_surface_area] }
    end
  end

  factory :worker_nature, parent: :product_nature do
    variety { 'worker' }
  end

  factory :plants_nature, class: ProductNature do
    sequence(:name)     { |n| "Plant nature - TEST#{n.to_s.rjust(8, '0')}" }
    population_counting { :unitary }
    variety             { :plant }

    variable_indicators_list { [:shape] }
    frozen_indicators_list   { [:net_surface_area] }
    association         :category, factory: :plants_category
  end

  factory :deliverable_nature, class: ProductNature do
    sequence(:name)     { |n| "Seed #{n}" }
    population_counting { :integer }
    variety             { 'seed' }

    association         :category, factory: :deliverable_category
  end

  factory :services_nature, class: ProductNature do
    sequence(:name)     { |n| "Service #{n}" }
    population_counting { :integer }
    variety             { 'service' }

    association         :category, factory: :deliverable_category
  end

  factory :equipment_nature, class: ProductNature do
    sequence(:name) { |n| "Equipment nature - #{n}" }
    population_counting { :integer }
    variety { :equipment }

    association :category, factory: :equipment_category
  end

  factory :building_division_nature, class: ProductNature do
    sequence(:name) { |n| "Building division nature - #{n}" }
    population_counting { 'unitary' }
    variety { 'building_division' }

    association :category, factory: :building_division_category
  end

  factory :fertilizer_nature, class: ProductNature do
    sequence(:name)     { |n| "Fertilizer - TEST#{n.to_s.rjust(8, '0')}" }
    population_counting { :decimal }
    variety { 'preparation' }

    association         :category, factory: :fertilizer_category
    variable_indicators_list { %i[approved_input_dose untreated_zone_length wait_before_entering_period] }
    frozen_indicators_list {   %i[net_mass net_volume wait_before_harvest_period] }
  end

  factory :tractor_nature, class: ProductNature do
    sequence(:name) { |n| "Tractor nature - #{n}" }
    population_counting { :unitary }
    variety { :tractor }

    abilities_list { %w[catch(equipment) tow(equipment) move] }

    association :category, factory: :tractor_category

    variable_indicators_list { %i[hour_counter] }
  end

  factory :seed_nature, class: ProductNature do
    sequence(:name) { |n| "Seed nature - #{n}" }
    population_counting { :decimal }
    variety { :seed }
    derivative_of { :plant }
    reference_name { :seed }

    abilities_list { %w[grow] }

    frozen_indicators_list { %i[grains_count net_mass thousand_grains_mass] }

    association :category, factory: :seed_category
  end

  factory :harvest_nature, class: ProductNature do
    sequence(:name) { |n| "Harvesting nature - #{n}" }
    population_counting { :decimal }
    variety { :vegetable }
    derivative_of { :plant }

    frozen_indicators_list { %i[net_mass] }

    association :category, factory: :harvest_category
  end

  # factory :equipment_nature, class: ProductNature do
  #   sequence(:name)     { |n| "Equipment nature - TEST#{n.to_s.rjust(8, '0')}" }
  #   population_counting { :unitary }
  #   variety             { :tractor }
  #   association         :category, factory: :equipment_category
  # end
end
