FactoryBot.define do
  factory :ugly_point_natures, class: ActivityInspectionPointNature do
    name { 'Ugly' }
    category { :deformity }
  end

  factory :sick_point_natures, class: ActivityInspectionPointNature do
    name { 'Sick' }
    category { :disease }
  end
end
