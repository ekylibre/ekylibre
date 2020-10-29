FactoryBot.define do
  factory :incoming_payment_mode do
    sequence(:name) { |n| "Bank Transfer #{n}" }
    cash
  end
end
