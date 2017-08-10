FactoryGirl.define do
  factory :fixed_asset_depreciation do
    fixed_asset
    amount "15.07".to_d
    started_on Date.parse('2057-08-01')
    stopped_on Date.parse('2057-08-10')
  end
end
