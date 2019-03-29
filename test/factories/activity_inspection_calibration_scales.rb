FactoryBot.define do
  factory :width_grading_scale, class: ActivityInspectionCalibrationScale do
    size_unit_name { 'centimeter' }
    size_indicator_name { :width }

    after(:create) do |instance|
      create :big_interval,   scale: instance, marketable: false
      create :small_interval, scale: instance, marketable: true
    end
  end

  factory :length_grading_scale, class: ActivityInspectionCalibrationScale do
    size_unit_name { 'centimeter' }
    size_indicator_name { :length }

    after(:create) do |instance|
      create :big_interval,   scale: instance, marketable: true
      create :small_interval, scale: instance, marketable: false
    end
  end
end
