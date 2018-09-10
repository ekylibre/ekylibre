FactoryBot.define do
  factory :fixed_asset do
    association :allocation_account, factory: :account
    depreciation_method { 'simplified_linear' }
    journal
    depreciable_amount { 860.32 }
    sequence(:name) { |n| "Fixed asset #{n}" }
    started_on { Date.civil(2017, 8, 11) }
    stopped_on { Date.civil(2020, 8, 10) }
    association :asset_account, factory: :account
    association :expenses_account, factory: :account
  end
end
