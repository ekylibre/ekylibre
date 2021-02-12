FactoryBot.define do
  factory :intervention_group_parameter do
    intervention
    reference_name { :zone }

    factory :sowing_group_parameter do
      after(:create) do |group|
        create :intervention_target, group: group, intervention: group.intervention
        create :plant_output, group: group, intervention: group.intervention
        group.reload
      end
    end
  end
end
