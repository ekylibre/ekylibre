FactoryGirl.define do
  factory :intervention_working_period do
    intervention
    started_at Time.now - 2.hour
    stopped_at Time.now - 1.hour
    duration 3600
  end
end
