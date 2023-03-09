FactoryBot.define do
  factory :intervention_parameter_setting do
    name { "Réglage nº1" }
    nature { 'spraying' }
    intervention
  end

  trait :with_indicators do
    after(:build) do |parameter_setting|
      parameter_setting.settings << build(:intervention_setting_item, :of_engine_speed)
      parameter_setting.settings << build(:intervention_setting_item, :of_ground_speed)
    end
  end
end
