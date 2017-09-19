FactoryGirl.define do
  factory :parcel do
    nature :outgoing
    planned_at { Time.now }
    # pretax_amount
    remain_owner false
    delivery_mode :us
    association :address, factory: :entity_address
    association :recipient, factory: :entity
  end
end
