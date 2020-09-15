FactoryBot.define do
  factory :product_nature_variant do
    unit_name { 'Millier de grains' }
    variety { 'cultivable_zone' }

    association :nature, factory: :product_nature
    association :category, factory: :product_nature_category
  end

  factory :worker_variant, parent: :product_nature_variant do
    association :nature, factory: :worker_nature
    variety { 'worker' }
  end

  factory :plant_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Plant variant - TEST#{n.to_s.rjust(8, '0')}" }
    variety { :triticum }
    unit_name { :hectare }

    association :nature, factory: :plants_nature
    association :category, factory: :plants_category
  end

  factory :corn_plant_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Corn plant variant - TEST#{n.to_s.rjust(8, '0')}" }
    variety { :zea_mays }
    unit_name { :hectare }
    association :category, factory: :deliverable_category
    association :nature, factory: :plants_nature
  end

  factory :deliverable_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Seed #{n}" }
    variety { 'seed' }
    unit_name { 'seeds' }

    association :nature, factory: :deliverable_nature
    association :category, factory: :deliverable_category
  end

  factory :service_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Service #{n}" }
    variety { 'service' }
    unit_name { 'hour' }

    association :nature, factory: :services_nature
    association :category, factory: :deliverable_category
  end

  factory :animal_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Animal #{n}" }
    variety { 'animal' }
    unit_name { 'unit' }

    association :nature, factory: :animals_nature
    association :category, factory: :animal_category
  end

  factory :building_division_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Building division variant - #{n}" }
    variety { 'building_division' }
    unit_name { 'Salle' }

    association :nature, factory: :building_division_nature
    association :category, factory: :building_division_category
  end

  factory :phytosanitary_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Plant Medicine variant - #{n}" }
    variety { :preparation }
    unit_name { :liter }

    association :nature, factory: :phytosanitary_nature
    association :category, factory: :phytosanitary_category
  end

  factory :fertilizer_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Fertilizer variant - #{n}" }
    variety { :preparation }
    unit_name { :liter }

    association :nature, factory: :fertilizer_nature
    association :category, factory: :fertilizer_category
  end

  factory :tractor_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Tractor variant - #{n}" }
    variety { :tractor }
    unit_name { 'Tracteur' }

    association :nature, factory: :tractor_nature
    association :category, factory: :tractor_category
  end

  factory :sower_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Sower variant - #{n}" }
    variety { :trailed_equipment }
    unit_name { 'Sower' }

    association :nature, factory: :sower_nature
    association :category, factory: :sower_category
  end

  factory :seed_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Seed variant - #{n}" }
    variety { :seed }
    derivative_of { :plant }
    unit_name { 'Millier de grains' }

    association :nature, factory: :seed_nature
    association :category, factory: :seed_category
  end

  factory :harvest_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Harvest variant - #{n}" }
    variety { :vegetable }
    derivative_of { :daucus }
    unit_name { 'Kg' }

    association :nature, factory: :harvest_nature
    association :category, factory: :harvest_category
  end

  factory :equipment_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Equipment variant - TEST#{n.to_s.rjust(8, '0')}" }
    variety { :tractor }
    unit_name { :equipment }
    association :category, factory: :equipment_category
    association :nature, factory: :equipment_nature
  end

  factory :land_parcel_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Land parcel variant - #{n}" }
    unit_name { :hectare }
    variety { :land_parcel }

    association :nature, factory: :land_parcel_nature
    association :category, factory: :land_parcel_category
  end

  factory :plant_medicine_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Plant medicine variant - #{n}" }
    variety { :preparation }
    unit_name { :liter }

    association :nature, factory: :plant_medicine_nature
    association :category, factory: :plant_medicine_category

    after(:build) do |variant|
      create :product_nature_variant_reading, :net_mass, variant: variant
    end
  end
end
