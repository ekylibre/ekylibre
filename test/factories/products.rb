FactoryBot.define do
  factory :product do
    association :category, factory: :product_nature_category
    association :nature, factory: :product_nature
    association :variant, factory: :product_nature_variant
    variety 'cultivable_zone'

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
end
