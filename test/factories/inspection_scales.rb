FactoryGirl.define do
  factory :width_grading_scale do
    minimal_value 100
    maximal_value 150
  end

  factory :length_grading_scale do
    minimal_value 150
    maximal_value 200
  end
end
