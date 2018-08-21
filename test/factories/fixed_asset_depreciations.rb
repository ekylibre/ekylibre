FactoryBot.define do
  factory :fixed_asset_depreciation do
    fixed_asset
    amount { 15.07 }
    started_on { Date.civil(2020, 8, 1) }
    stopped_on { Date.civil(2020, 8, 10) }
  end
end
