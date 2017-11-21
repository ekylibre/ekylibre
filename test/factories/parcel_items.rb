FactoryGirl.define do
  factory :parcel_item do
    parcel
    association :variant, factory: :product_nature_variant

    factory :shipment_item do
      association :parcel, factory: :shipment
      association :source_product, factory: :product
    end

    factory :reception_item do
      association :parcel, factory: :reception
    end
  end
end
