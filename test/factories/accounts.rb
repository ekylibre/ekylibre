FactoryBot.define do
  factory :account do
    debtor false
    reconcilable false
    nature 'general'
    sequence(:name) { |n| "801 - Compte général #{n}" }
    sequence(:number) { |n| "8010000#{n}" }

    trait :centralizing do
      nature 'centralizing'
      sequence(:name) { |n| "411 - Compte centralisateur #{n}" }
      sequence(:number) { |n| "411#{n}" }
    end

    trait :auxiliary do
      nature 'auxiliary'
      sequence(:name) { |n| "411 - Compte auxiliaire #{n}" }
      sequence(:number) { |n| "4110000#{n}" }
    end
  end
end
