FactoryGirl.define do
  factory :intervention do
    procedure_name 'sowing'
    started_at Time.now - 2.hour
    stopped_at Time.now - 1.hour
    working_duration 3600
    actions [:sowing]

    factory :spraying do
      procedure_name 'spraying'
      actions [:fungicide]
    end
  end
end
