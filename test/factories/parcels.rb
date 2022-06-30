FactoryBot.define do
  factory :parcel do
    association :address, factory: :entity_address

    nature { :incoming }

    factory :outgoing_parcel do
      nature { :outgoing }
      planned_at { Time.now }
      state { :draft }
      # pretax_amount
      remain_owner { false }
      delivery_mode { :us }
      association :recipient, factory: :entity
    end
  end
end
