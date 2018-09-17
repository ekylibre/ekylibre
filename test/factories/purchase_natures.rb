FactoryBot.define do
  factory :purchase_nature do
    currency 'EUR'
    nature 'purchase'
    sequence(:name) { |n| "Purchase n° #{n}" }
  end

  trait :with_accounting do
    with_accounting true
    journal
  end
end
