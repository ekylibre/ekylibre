FactoryBot.define do
  factory :parcel do
    association :address, factory: :entity_address

    factory :outgoing_parcel do
      nature :outgoing
      planned_at { Time.now }
      # pretax_amount
      remain_owner false
      delivery_mode :us
    end
  end
end
