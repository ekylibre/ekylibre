FactoryBot.define do
  factory :intervention do
    procedure_name { 'sowing' }
    started_at { Time.now - 2.hours }
    stopped_at { Time.now - 1.hour }
    working_duration { 3600 }
    actions { [:sowing] }
  end
end
