FactoryBot.define do
  factory :parcel_item do
    parcel
    association :variant, factory: :product_nature_variant
  end
end
