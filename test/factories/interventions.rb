FactoryBot.define do
  factory :intervention do
    procedure_name { 'sowing' }
    started_at { DateTime.new(2018, 1, 1) - 2.hours }
    stopped_at { DateTime.new(2018, 1, 1) - 1.hour }
    working_duration { 3600 }
    actions { [:sowing] }
  end
end
