FactoryBot.define do
  factory :outgoing_payment do
    transient do
      at { nil }
    end
    amount { 5000.0 }
    currency { 'EUR' }
    association :mode, factory: :outgoing_payment_mode
    association :payee, factory: :entity
    association :responsible, factory: :user
    to_bank_at { at }
    paid_at { at }
  end
end
