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

        driver = create :driver, intervention: intervention
        intervention.doers << driver

        tractor = create :tractor_tool, intervention: intervention
        intervention.tools << tractor

        sower = create :sower_tool, intervention: intervention
        intervention.tools << sower
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

    trait :spraying do
      procedure_name { 'spraying' }
      actions { %i[herbicide fungicide insecticide growth_regulator biostimulation molluscicide nematicide acaricide bactericide rodenticide talpicide corvicide game_repellent virucide desiccation fireproofing] }
      after(:build) do |intervention|
        intervention.inputs << build(:intervention_input, reference_name: 'plant_medicine', product: create(:phytosanitary_product), intervention: intervention, allowed_entry_factor: 'PT6H',
 allowed_harvest_factor: 'P3D')
      end
    end

    trait :with_target do
      transient do
        on { nil }
        reference_name { :cultivation }
      end

      after(:build) do |intervention, evaluator|
        intervention.targets << build(:intervention_target, product: evaluator.on, working_zone: evaluator.on&.initial_shape, intervention: intervention, reference_name: evaluator.reference_name)
      end
    end
  end
end
