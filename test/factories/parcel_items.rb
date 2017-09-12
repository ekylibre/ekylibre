FactoryGirl.define do
  factory :parcel_item do
    association :parcel, factory: :parcel
    association :source_product, factory: :product
  end
end
