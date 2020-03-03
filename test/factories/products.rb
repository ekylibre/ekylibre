FactoryBot.define do
  factory :product do
    association :category, factory: :product_nature_category
    association :nature, factory: :product_nature
    association :variant, factory: :product_nature_variant
    variety { 'cultivable_zone' }

    trait :with_boolean_reading do
      after(:create) do |instance|
        create :product_reading, :boolean, product: instance
      end
    end

    trait :with_choice_reading do
      after(:create) do |instance|
        create :product_reading, :choice, product: instance
      end
    end

    trait :with_decimal_reading do
      after(:create) do |instance|
        create :product_reading, :decimal, product: instance
      end
    end

    trait :with_geometry_reading do
      after(:create) do |instance|
        create :product_reading, :geometry, product: instance
      end
    end

    trait :with_integer_reading do
      after(:create) do |instance|
        create :product_reading, :integer, product: instance
      end
    end

    trait :with_measure_reading do
      after(:create) do |instance|
        create :product_reading, :measure, product: instance
      end
    end

    trait :with_multi_polygon_reading do
      after(:create) do |instance|
        create :product_reading, :multi_polygon, product: instance
      end
    end

    trait :with_point_reading do
      after(:create) do |instance|
        create :product_reading, :point, product: instance
      end
    end

    trait :with_string_reading do
      after(:create) do |instance|
        create :product_reading, :string, product: instance
      end
    end
  end

  factory :asset_fixable_product, class: Product do
    association :category, factory: :equipment_category
    association :nature, factory: :equipment_nature
    association :variant, factory: :equipment_variant
    variety { 'tractor' }
  end

  factory :fertilizer_product, class: Product do
    association :category, factory: :fertilizer_category
    association :nature, factory: :fertilizer_nature
    association :variant, factory: :fertilizer_variant
    variety { :preparation }
  end

  factory :seed_product, class: Product do
    association :category, factory: :seed_category
    association :nature, factory: :seed_nature
    association :variant, factory: :seed_variant
    variety { :seed }
    derivative_of { :plant }
  end

  factory :phytosanitary_product, class: Product do
    association :variant, factory: :plant_medicine_variant
    variety { :preparation }

    after(:build) do |product|
      product.category = product.variant.category
      product.nature = product.variant.nature
    end
  end
end
