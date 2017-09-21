FactoryGirl.define do
  factory :parcel_item do
    association :parcel, factory: :parcel
    association :source_product, factory: :product
    unit_pretax_amount {rand(1..100)}
  end
end
