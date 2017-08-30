FactoryGirl.define do
  factory :parcel do
    association :sender, factory: :entity
    association :storage, factory: :product
    association :address, factory: :entity_address
  end
end
