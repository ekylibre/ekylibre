FactoryGirl.define do
  factory :account do
    debtor false
    reconcilable false
    sequence(:name) { |n| "801 - Compte #{n}" }
    sequence(:number) { |n| "801000000#{n}" }
  end
end
