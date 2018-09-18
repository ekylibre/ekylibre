FactoryBot.define do
  factory :account do
    debtor { false }
    reconcilable { false }
    sequence(:name) { |n| "801 - Compte #{n}" }
    sequence(:number) { |n| (80_100_000 + n).to_s }
  end
end
