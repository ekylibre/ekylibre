FactoryGirl.define do
  factory :product_nature do
    sequence(:name)     { |n| "Semence #{n}" }
    population_counting 'unitary'
    variety             'cultivable_zone'

    association         :category, factory: :product_nature_category

    factory :land_parcel_nature do
      sequence(:name)     { |n| "Land Parcel #{n}" }
      variety 'land_parcel'
      variable_indicators_list [:shape]
      frozen_indicators_list   [:net_surface_area]
    end

    factory :preparation_nature do
      sequence(:name)     { |n| "Preparation #{n}" }
      variety 'preparation'
      population_counting 'decimal'
    end

    factory :equipment_nature do
      sequence(:name)     { |n| "Equipment #{n}" }
      variety 'equipment'
    end
  end

  factory :plants_nature, class: ProductNature do
    sequence(:name)     { |n| "Plant nature - TEST#{n.to_s.rjust(8, '0')}" }
    population_counting :unitary
    variety             :plant

    association         :category, factory: :plants_category
  end
end
