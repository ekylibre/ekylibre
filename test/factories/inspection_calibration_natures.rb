FactoryBot.define do
  factory :small_interval, class: ActivityInspectionCalibrationNature do
    minimal_value { 100 }
    maximal_value { 150 }
  end

  factory :big_interval, class: ActivityInspectionCalibrationNature do
    minimal_value { 150 }
    maximal_value { 200 }
  end
end
