FactoryBot.define do
  factory :entity_address do
    entity
    canal { 'email' }
    by_default { true }
    mail_auto_update { false }
    sequence(:coordinate) { |n| "email#{n}@test.com" }

    trait :email do
    end

    trait :mail do
      canal { 'mail' }
      mail_line_4 { "4 Rue Charles Domercq" }
      mail_line_6 { "33130 Bègles"}
      mail_country { "fr" }
    end
  end
end
