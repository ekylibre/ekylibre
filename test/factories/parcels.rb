FactoryGirl.define do
  factory :parcel do
    association :address, factory: :entity_address
    association :sender, factory: :entity
    association :storage, factory: :product

    factory :outgoing_parcel do
      nature :outgoing
      planned_at { Time.now }
      # pretax_amount
      remain_owner false
      delivery_mode :us
      association :recipient, factory: :entity
    end
  end
end
