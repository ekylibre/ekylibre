FactoryBot.define do
  factory :intervention_group_parameter do
    intervention
    reference_name { :zone }

    factory :sowing_group_parameter do
      after(:create) do |group|
        target = create :intervention_target, group: group, intervention: group.intervention
        group.targets << target
        output = create :plant_output, group: group, intervention: group.intervention
        group.outputs << output
      end
    end
  end
end

