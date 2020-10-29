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

  factory :plants_nature, class: ProductNature do
    sequence(:name)     { |n| "Plant nature - TEST#{n.to_s.rjust(8, '0')}" }
    population_counting { :unitary }
    variety             { :plant }

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

  factory :equipments_nature, class: ProductNature do
    sequence(:name)     { |n| "Equipment nature - TEST#{n.to_s.rjust(8, '0')}" }
    population_counting { :unitary }
    variety             { :tractor }
    association         :category, factory: :equipments_category
  end
end
