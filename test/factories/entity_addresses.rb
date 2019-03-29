FactoryBot.define do
  factory :entity_address do
    entity
    canal { 'email' }
    by_default { true }
    mail_auto_update { false }
    sequence(:coordinate) { |n| "email#{n}@test.com" }

    trait :email do
    end
  end
end
