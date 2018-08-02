FactoryBot.define do
  factory :account do
    debtor false
    reconcilable false
    nature 'general'
    sequence(:name) { |n| "801 - Compte général #{n}" }
    # Validation will take care to get a 8 character length number
    sequence(:number) { |n| "801#{n}" }

    trait :centralizing do
      nature 'centralizing'
      sequence(:name) { |n| "411 - Compte centralisateur #{n}" }
      sequence(:number) { |n| "41#{n}" }
    end

    trait :auxiliary do
      nature 'auxiliary'
      sequence(:name) { |n| "411 - Compte auxiliaire #{n}" }
      sequence(:number) { |n| "411000 12#{n}" }
    end
  end
end
