FactoryBot.define do
  factory :intervention do
    procedure_name { 'sowing' }
    started_at { DateTime.new(2018, 1, 1) - 2.hours }
    stopped_at { DateTime.new(2018, 1, 1) - 1.hour }
    working_duration { 3600 }
    actions { [:sowing] }

    factory :sowing_intervention_with_all_parameters do
      after(:create) do |intervention|
        gp = create :sowing_group_parameter, intervention: intervention
        intervention.group_parameters << gp
        input = create :intervention_input, intervention: intervention
        intervention.inputs << input
      end
    end

    trait :harvesting do
      procedure_name { 'harvesting' }
      actions { [:harvest] }
    end

    trait :with_working_period do
      after(:build) do |intervention|
        create_list :intervention_working_period, 1, intervention: intervention
      end
    end

    trait :with_tractor_tool do
      transient do
        tractor_count { 2 }
      end

      after(:build) do |intervention, evaluator|
        create_list :tractor_tool, evaluator.tractor_count , intervention: intervention
      end
    end
  end
end
