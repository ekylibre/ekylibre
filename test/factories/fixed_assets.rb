FactoryGirl.define do
  factory :fixed_asset do
    association :allocation_account, factory: :account
    depreciation_method 'simplified_linear'
    journal
    depreciable_amount "860.32".to_d
    sequence(:name) { |n| "Fixed asset #{n}" }
    started_on Date.parse('2017-08-11')
    stopped_on Date.parse('2057-08-10')
    association :asset_account, factory: :account
    association :expenses_account, factory: :account
  end
end
