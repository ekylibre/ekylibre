FactoryBot.define do
  factory :intervention_working_period do
    intervention
    started_at { '2016-09-30T11:00:00.000+0200' }
    stopped_at { '2016-09-30T11:30:00.000+0200' }
  end
end
