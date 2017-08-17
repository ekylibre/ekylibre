FactoryGirl.define do
  factory :parcel do
    association :address, factory: :entity_address
    association :sender, factory: :entity
    association :storage, factory: :product
  end
end
