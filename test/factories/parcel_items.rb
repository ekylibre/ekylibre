FactoryGirl.define do
  factory :parcel_item do
    parcel
    association :variant, factory: :product_nature_variant

    factory :outgoing_parcel_item do
      association :parcel, factory: :outgoing_parcel
      association :source_product, factory: :product
    end
  end
end
