FactoryGirl.define do
  factory :activity_production do
    activity
    campaign

    factory :corn_activity_production do
      association :activity, factory: :corn_activity
    end
  end
end
